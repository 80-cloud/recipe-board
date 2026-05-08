-- ============================================
-- MySQL 初期セットアップ: recipe_user に test DB 等への権限付与
-- ============================================
-- docker-compose の MYSQL_DATABASE で作成される DB は recipe_board_development のみ。
-- Rails の db:create が test DB を作成する際、recipe_user に CREATE 権限が必要。
-- 本スクリプトは docker entrypoint の /docker-entrypoint-initdb.d/ 内に配置すれば
-- 初回起動時に自動実行される。
-- ============================================

GRANT ALL PRIVILEGES ON `recipe_board_%`.* TO 'recipe_user'@'%';
FLUSH PRIVILEGES;
