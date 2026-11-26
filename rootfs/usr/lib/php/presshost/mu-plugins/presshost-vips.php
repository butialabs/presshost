<?php
/**
 * Plugin Name: PressHost: libvips
 * Description: Processes uploads with libvips (IMAGE_PROCESSOR=vips).
 * Author: PressHost
 */

defined('ABSPATH') || exit;

if (defined('PRESSHOST_VIPS_LOADED')) {
    return;
}
define('PRESSHOST_VIPS_LOADED', true);

defined('PRESSHOST_VIPS_DIR') || define('PRESSHOST_VIPS_DIR', '/usr/lib/php/presshost/vips');

if (!function_exists('presshost_vips_bootstrap')) :

function presshost_vips_bootstrap(): bool
{
    static $loaded = null;
    if ($loaded !== null) {
        return $loaded;
    }
    $loaded = false;

    if (!extension_loaded('ffi') || !is_readable(PRESSHOST_VIPS_DIR . '/vendor/autoload.php')) {
        return false;
    }

    require_once PRESSHOST_VIPS_DIR . '/vendor/autoload.php';
    require_once ABSPATH . WPINC . '/class-wp-image-editor.php';
    require_once PRESSHOST_VIPS_DIR . '/class-presshost-image-editor-vips.php';

    $loaded = true;
    return true;
}
endif;

add_filter('wp_image_editors', static function ($editors) {
    if (presshost_vips_bootstrap()) {
        $editors = array_values(array_diff((array) $editors, ['PressHost_Image_Editor_Vips']));
        array_unshift($editors, 'PressHost_Image_Editor_Vips');
    }
    return $editors;
});

add_filter('debug_information', static function ($info) {
    $fields = [
        'processor' => [
            'label' => 'Image processor',
            'value' => 'vips (fallback: GD)',
        ],
    ];

    if (!presshost_vips_bootstrap()) {
        $fields['status'] = ['label' => 'Status', 'value' => 'php-vips or FFI not available'];
    } elseif (!PressHost_Image_Editor_Vips::test()) {
        $fields['status'] = [
            'label' => 'Status',
            'value' => 'libvips not usable (ffi.enable=' . ini_get('ffi.enable') . '); WordPress is using GD',
        ];
    } else {
        $formats = [];
        foreach (PressHost_Image_Editor_Vips::MIME_OPERATIONS as $mime => $ops) {
            $formats[] = $mime . (PressHost_Image_Editor_Vips::supports_mime_type($mime) ? '' : ' (unavailable)');
        }
        $fields['status']      = ['label' => 'Status', 'value' => 'active'];
        $fields['version']     = ['label' => 'libvips version', 'value' => PressHost_Image_Editor_Vips::vips_version()];
        $fields['concurrency'] = ['label' => 'Threads per process', 'value' => (string) (getenv('VIPS_CONCURRENCY') ?: 'libvips default')];
        $fields['formats']     = ['label' => 'Formats', 'value' => implode(', ', $formats)];
    }

    $info['presshost-image'] = [
        'label'  => 'PressHost Image',
        'fields' => $fields,
    ];
    return $info;
});
