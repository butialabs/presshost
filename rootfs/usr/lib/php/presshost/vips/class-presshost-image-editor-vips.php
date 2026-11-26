<?php
defined('ABSPATH') || exit;

use Jcupitt\Vips;

class PressHost_Image_Editor_Vips extends WP_Image_Editor
{
    public const MIME_OPERATIONS = [
        'image/jpeg'      => ['jpegload', 'jpegsave'],
        'image/png'       => ['pngload', 'pngsave'],
        'image/webp'      => ['webpload', 'webpsave'],
        'image/gif'       => ['gifload', 'gifsave'],
        'image/avif'      => ['heifload', 'heifsave'],
        'image/heic'      => ['heifload', null],
        'image/heif'      => ['heifload', null],
        'image/tiff'      => ['tiffload', 'tiffsave'],
        'application/pdf' => ['pdfload', null],
    ];

    private const SAVE_SUFFIX = [
        'image/jpeg' => '.jpg',
        'image/png'  => '.png',
        'image/webp' => '.webp',
        'image/gif'  => '.gif',
        'image/avif' => '.avif',
        'image/tiff' => '.tif',
    ];

    private const KEEP_ICC = 8;

    /** @var Vips\Image|null */
    protected $image = null;

    private static ?bool $usable = null;
    private static array $mime_support = [];

    public function __destruct()
    {
        $this->image = null;
    }

    /**
     * @param array $args
     */
    public static function test($args = array())
    {
        if (self::$usable !== null) {
            return self::$usable;
        }
        self::$usable = false;

        if (!extension_loaded('ffi') || !class_exists(Vips\Image::class)) {
            return false;
        }
        $ffi = strtolower((string) ini_get('ffi.enable'));
        if (!in_array($ffi, ['1', 'true', 'on', 'yes'], true)) {
            return false;
        }

        try {
            Vips\Config::version();
            Vips\Config::cacheSetMax(0);
        } catch (\Throwable $e) {
            return false;
        }

        self::$usable = true;
        return true;
    }

    public static function vips_version(): string
    {
        try {
            return Vips\Config::version();
        } catch (\Throwable $e) {
            return 'unknown';
        }
    }

    /**
     * @param string $mime_type
     */
    public static function supports_mime_type($mime_type)
    {
        if (!isset(self::MIME_OPERATIONS[$mime_type]) || !self::test()) {
            return false;
        }
        if (isset(self::$mime_support[$mime_type])) {
            return self::$mime_support[$mime_type];
        }

        [$loader, $saver] = self::MIME_OPERATIONS[$mime_type];
        $ok = self::has_operation($loader) && ($saver === null || self::has_operation($saver));

        if ($ok && $mime_type === 'image/avif') {
            try {
                Vips\Image::black(16, 16)->writeToBuffer('.avif', ['effort' => 0]);
            } catch (\Throwable $e) {
                $ok = false;
            }
        }

        self::$mime_support[$mime_type] = $ok;
        return $ok;
    }

    private static function has_operation(string $name): bool
    {
        try {
            Vips\VipsOperation::newFromName($name);
            return true;
        } catch (\Throwable $e) {
            return false;
        }
    }

    public function load()
    {
        if ($this->image) {
            return true;
        }

        if (!is_file($this->file)) {
            return new WP_Error('error_loading_image', __('File does not exist?'), $this->file);
        }

        wp_raise_memory_limit('image');

        $mime = wp_get_image_mime($this->file);
        if (!$mime) {
            $filetype = wp_check_filetype($this->file);
            $mime = $filetype['type'] ?? false;
        }
        if (!$mime || !isset(self::MIME_OPERATIONS[$mime])) {
            return new WP_Error('invalid_image', __('File is not an image.'), $this->file);
        }

        $options = [];
        if ($mime === 'application/pdf') {
            $options = ['page' => 0, 'dpi' => 128];
        }

        try {
            $this->image = Vips\Image::newFromFile($this->file, $options);
        } catch (\Throwable $e) {
            return new WP_Error('invalid_image', $e->getMessage(), $this->file);
        }

        $this->mime_type = $mime;
        $this->update_size($this->image->width, $this->image->height);

        return $this->set_quality();
    }

    public function resize($max_w, $max_h, $crop = false)
    {
        if ((int) $this->size['width'] === (int) $max_w && (int) $this->size['height'] === (int) $max_h) {
            return true;
        }

        $resized = $this->_resize($max_w, $max_h, $crop);
        if (is_wp_error($resized)) {
            return $resized;
        }

        $this->image = $resized;
        return true;
    }

    /**
     * @return Vips\Image|WP_Error
     */
    protected function _resize($max_w, $max_h, $crop = false)
    {
        $dims = image_resize_dimensions($this->size['width'], $this->size['height'], $max_w, $max_h, $crop);
        if (!$dims) {
            return new WP_Error('error_getting_dimensions', __('Could not calculate resized image dimensions'), $this->file);
        }

        [, , $src_x, $src_y, $dst_w, $dst_h, $src_w, $src_h] = $dims;

        try {
            $image = $this->image;
            if ($src_x || $src_y || (int) $src_w !== (int) $this->size['width'] || (int) $src_h !== (int) $this->size['height']) {
                $image = $image->extract_area((int) $src_x, (int) $src_y, (int) $src_w, (int) $src_h);
            }
            $image = $this->scale($image, (int) $dst_w, (int) $dst_h);
        } catch (\Throwable $e) {
            return new WP_Error('image_resize_error', $e->getMessage(), $this->file);
        }

        $this->update_size($image->width, $image->height);
        return $image;
    }
    private function scale(Vips\Image $image, int $width, int $height): Vips\Image
    {
        if ($width < 1 || $height < 1 || ($width === $image->width && $height === $image->height)) {
            return $image;
        }

        $hscale = $width / $image->width;
        $vscale = $height / $image->height;

        if ($image->hasAlpha()) {
            $format = $image->format;
            return $image->premultiply()
                ->resize($hscale, ['vscale' => $vscale, 'kernel' => 'lanczos3'])
                ->unpremultiply()
                ->cast($format);
        }

        return $image->resize($hscale, ['vscale' => $vscale, 'kernel' => 'lanczos3']);
    }

    public function multi_resize($sizes)
    {
        $metadata = array();

        foreach ($sizes as $size => $size_data) {
            $meta = $this->make_subsize($size_data);
            if (!is_wp_error($meta)) {
                $metadata[$size] = $meta;
            }
        }

        return $metadata;
    }

    public function make_subsize($size_data)
    {
        if (!isset($size_data['width']) && !isset($size_data['height'])) {
            return new WP_Error('image_subsize_create_error', __('Cannot resize the image. Both width and height are not set.'));
        }

        $orig_size = $this->size;

        $width  = $size_data['width'] ?? null;
        $height = $size_data['height'] ?? null;
        $crop   = $size_data['crop'] ?? false;

        $resized = $this->_resize($width, $height, $crop);
        if (is_wp_error($resized)) {
            $saved = $resized;
        } else {
            $saved = $this->_save($resized);
        }

        $this->size = $orig_size;

        if (!is_wp_error($saved)) {
            unset($saved['path']);
        }

        return $saved;
    }

    public function crop($src_x, $src_y, $src_w, $src_h, $dst_w = null, $dst_h = null, $src_abs = false)
    {
        if ($src_abs) {
            $src_w -= $src_x;
            $src_h -= $src_y;
        }

        $width  = (int) $this->size['width'];
        $height = (int) $this->size['height'];

        $src_x = max(0, min((int) round($src_x), $width - 1));
        $src_y = max(0, min((int) round($src_y), $height - 1));
        $src_w = max(1, min((int) round($src_w), $width - $src_x));
        $src_h = max(1, min((int) round($src_h), $height - $src_y));

        try {
            $image = $this->image->extract_area($src_x, $src_y, $src_w, $src_h);
            if ($dst_w && $dst_h) {
                $image = $this->scale($image, (int) round($dst_w), (int) round($dst_h));
            }
        } catch (\Throwable $e) {
            return new WP_Error('image_crop_error', $e->getMessage(), $this->file);
        }

        $this->image = $image;
        $this->update_size($image->width, $image->height);
        return true;
    }

    /**
     * @param float $angle Degrees counter-clockwise (same as GD/Imagick editors).
     */
    public function rotate($angle)
    {
        $clockwise = fmod(360 - fmod((float) $angle, 360), 360);
        if ($clockwise < 0) {
            $clockwise += 360;
        }

        $map = [0 => null, 90 => 'd90', 180 => 'd180', 270 => 'd270'];
        $key = (int) round($clockwise);
        if (abs($clockwise - $key) > 0.001 || !array_key_exists($key % 360, $map)) {
            return new WP_Error('image_rotate_error', __('Image rotate failed.'), $this->file);
        }

        $direction = $map[$key % 360];
        if ($direction === null) {
            return true;
        }

        try {
            $this->image = $this->image->rot($direction);
        } catch (\Throwable $e) {
            return new WP_Error('image_rotate_error', $e->getMessage(), $this->file);
        }

        $this->update_size($this->image->width, $this->image->height);
        return true;
    }

    public function flip($horz, $vert)
    {
        try {
            if ($horz) {
                $this->image = $this->image->flip('vertical');
            }
            if ($vert) {
                $this->image = $this->image->flip('horizontal');
            }
        } catch (\Throwable $e) {
            return new WP_Error('image_flip_error', $e->getMessage(), $this->file);
        }

        return true;
    }

    public function save($destfilename = null, $mime_type = null)
    {
        $saved = $this->_save($this->image, $destfilename, $mime_type);

        if (!is_wp_error($saved)) {
            $this->file      = $saved['path'];
            $this->mime_type = $saved['mime-type'];
        }

        return $saved;
    }

    /**
     * @return array|WP_Error
     */
    protected function _save($image, $filename = null, $mime_type = null)
    {
        [$filename, $extension, $mime_type] = $this->get_output_format($filename, $mime_type);

        if (!isset(self::SAVE_SUFFIX[$mime_type])) {
            $mime_type = 'image/jpeg';
            $extension = 'jpg';
            if ($filename) {
                $filename = preg_replace('/\.[^.\/]+$/', '', $filename) . '.jpg';
            }
        }

        if (!$filename) {
            $filename = $this->generate_filename(null, null, $extension);
        }

        $buffer = $this->encode($image, $mime_type);
        if (is_wp_error($buffer)) {
            return $buffer;
        }

        if (!wp_mkdir_p(dirname($filename)) || false === file_put_contents($filename, $buffer)) {
            return new WP_Error('image_save_error', __('Image Editor Save Failed'), $filename);
        }

        // Match the permissions of the parent directory, like the core editors.
        $stat  = stat(dirname($filename));
        $perms = $stat['mode'] & 0000666;
        chmod($filename, $perms);

        return array(
            'path'      => $filename,
            'file'      => wp_basename(apply_filters('image_make_intermediate_size', $filename)),
            'width'     => $this->size['width'],
            'height'    => $this->size['height'],
            'mime-type' => $mime_type,
            'filesize'  => function_exists('wp_filesize') ? wp_filesize($filename) : (int) @filesize($filename),
        );
    }

    public function stream($mime_type = null)
    {
        [, , $mime_type] = $this->get_output_format(null, $mime_type);
        if (!isset(self::SAVE_SUFFIX[$mime_type])) {
            $mime_type = 'image/jpeg';
        }

        $buffer = $this->encode($this->image, $mime_type);
        if (is_wp_error($buffer)) {
            return $buffer;
        }

        header("Content-Type: $mime_type");
        echo $buffer;
        return true;
    }

    /**
     * @return string|WP_Error
     */
    private function encode(Vips\Image $image, string $mime_type)
    {
        if (!isset(self::SAVE_SUFFIX[$mime_type])) {
            return new WP_Error('image_save_error', __('Image Editor Save Failed'), $mime_type);
        }

        try {
            $image = $this->prepare_for_save($image, $mime_type);
            return $image->writeToBuffer(self::SAVE_SUFFIX[$mime_type], $this->save_options($mime_type));
        } catch (\Throwable $e) {
            return new WP_Error('image_save_error', $e->getMessage(), $this->file);
        }
    }

    private function prepare_for_save(Vips\Image $image, string $mime_type): Vips\Image
    {
        $interpretation = $image->interpretation;

        if ($interpretation === 'cmyk') {
            try {
                $image = $image->icc_transform('srgb', ['input_profile' => 'cmyk', 'embedded' => true, 'intent' => 'perceptual']);
            } catch (\Throwable $e) {
                $image = $image->colourspace('srgb');
            }
        } elseif (!in_array($interpretation, ['srgb', 'rgb', 'b-w', 'rgb16', 'grey16'], true)) {
            $image = $image->colourspace('srgb');
        }

        if ($mime_type === 'image/jpeg' && $image->hasAlpha()) {
            $background = $image->bands > 2 ? [255, 255, 255] : [255];
            $image = $image->flatten(['background' => $background]);
        }

        return $image;
    }

    private function save_options(string $mime_type): array
    {
        $quality = (int) $this->get_quality();

        $options = Vips\Config::atLeast(8, 15) ? ['keep' => self::KEEP_ICC] : ['strip' => true];

        switch ($mime_type) {
            case 'image/jpeg':
                $options += ['Q' => $quality, 'optimize_coding' => true];
                break;
            case 'image/png':
                $options += ['compression' => 6];
                break;
            case 'image/webp':
                $options += ['Q' => $quality, 'effort' => 4];
                break;
            case 'image/avif':
                $options += ['Q' => $quality, 'effort' => 3];
                break;
            case 'image/tiff':
                $options += ['compression' => 'deflate'];
                break;
        }

        return $options;
    }
}
