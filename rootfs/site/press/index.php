<?php
$nginx_version = getenv('NGINX_VERSION');
if (preg_match('/^[0-9]+(?:\.[0-9]+){1,2}/', $nginx_version, $m)) {
    $nginx_version = $m[0];
}
$load = sys_getloadavg();
$load_avg = sprintf('%.2f, %.2f, %.2f', $load[0], $load[1], $load[2]);
$process_count = count(glob('/proc/[0-9]*'));
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
            <li><strong>Hostname:</strong> <?= htmlspecialchars(gethostname(), ENT_QUOTES, 'UTF-8') ?></li>
            <li><strong>OS:</strong> <?= htmlspecialchars(PHP_OS, ENT_QUOTES, 'UTF-8') ?> (<?= htmlspecialchars(php_uname('m'), ENT_QUOTES, 'UTF-8') ?>)</li>
            <li><strong>Kernel:</strong> <?= htmlspecialchars(php_uname('r'), ENT_QUOTES, 'UTF-8') ?></li>
            <li><strong>PHP:</strong> <?= htmlspecialchars(PHP_VERSION, ENT_QUOTES, 'UTF-8') ?></li>
            <li><strong>Nginx:</strong> <?= htmlspecialchars($nginx_version, ENT_QUOTES, 'UTF-8') ?></li>
            <li><strong>Processes:</strong> <?= $process_count ?></li>
            <li><strong>Load Avg:</strong> <?= htmlspecialchars($load_avg, ENT_QUOTES, 'UTF-8') ?></li>
            <li><strong>Server IP:</strong> <?= htmlspecialchars($_SERVER['SERVER_ADDR'], ENT_QUOTES, 'UTF-8') ?></li>
            <li><strong>Server Time:</strong> <?= htmlspecialchars(date('Y-m-d H:i:s T'), ENT_QUOTES, 'UTF-8') ?></li>
        </ul>
        <p>$<span class="blink">_</span></p>
    </div>
</body>

</html>
