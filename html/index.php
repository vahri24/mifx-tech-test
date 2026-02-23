<?php
// index.php
$title = "Simple PHP Page";
?>
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title><?php echo $title; ?></title>
</head>
<body>
  <h1><?php echo $title; ?></h1>
  <p>Hello World! This is a simple HTML page rendered using PHP.</p>

  <p>Today is: <?php echo date("Y-m-d"); ?></p>
</body>
</html>
