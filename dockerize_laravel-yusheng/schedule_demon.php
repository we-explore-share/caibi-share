<?php
while (true){
    exec('php artisan schedule:run >> /dev/null 2>&1');
    sleep(60);
}