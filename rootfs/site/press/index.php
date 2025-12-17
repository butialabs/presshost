<?php

function get_nginx_version()
{
    $output = @shell_exec('nginx -v 2>&1');
    if (preg_match('/nginx\/([0-9.]+)/', $output, $matches)) {
        return $matches[1];
    }
    return 'N/A';
}

function get_kernel_version()
{
    return php_uname('r');
}

function get_process_count()
{
    if (PHP_OS_FAMILY === 'Linux') {
        $count = @shell_exec('ps aux | wc -l');
        return $count ? trim($count) : 'N/A';
    }
    return 'N/A';
}
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="robots" content="noindex, nofollow" />
    <title>PressHost</title>

    <link rel="preconnect" href="https://fonts.gstatic.com">
    <link rel="preconnect" href="https://cdn.jsdelivr.net">
    <link rel="stylesheet" href="//fonts.googleapis.com/css2?family=Source+Code+Pro:wght@400;700&display=swap">
    <link rel="stylesheet" href="//cdn.jsdelivr.net/npm/bootstrap@5.3.1/dist/css/bootstrap.min.css">

    <style>
        body {
            background: #222225;
            font-family: 'Source Code Pro', monospace;
            color: #FFF;
            padding: 1rem;
            font-size: 16px;
            height: 100%;
        }

        a {
            color: #8d73bd;
            text-decoration: none;
        }

        a:hover {
            background-color: #8d73bd;
            color: #222225;
        }

        h3 {
            color: #E09690
        }

        .blink {
            color: #fff;
            animation: blink 1s steps(5, start) infinite;
        }

        @keyframes blink {
            to {
                visibility: hidden;
            }
        }
    </style>
</head>

<body>
    <div class="container py-4">
        <header>
            <h1 class="fs-4 fw-bold">$ PressHost</h1>
            <h2 class="fs-5">Olá!</h2>
        </header>
        <h3 class="fs-6 mt-4">[?] Server Stats</h3>
        <ul>
            <li><strong>Hostname:</strong> <?= gethostname() ?></li>
            <li><strong>OS:</strong> <?= PHP_OS ?> (<?= php_uname('m') ?>)</li>
            <li><strong>Kernel:</strong> <?= get_kernel_version() ?></li>
            <li><strong>PHP:</strong> <?= PHP_VERSION ?></li>
            <li><strong>Nginx:</strong> <?= get_nginx_version() ?></li>
            <li><strong>Processes:</strong> <?= get_process_count() ?></li>
            <li><strong>Server IP:</strong> <?= $_SERVER['SERVER_ADDR'] ?? gethostbyname(gethostname()) ?></li>
            <li><strong>Server Time:</strong> <?= date('Y-m-d H:i:s T') ?></li>
        </ul>
        <p>$<span class="blink">_</span></p>
    </div>
</body>

</html>