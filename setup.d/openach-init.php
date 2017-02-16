<?php

class Config
{
	static $backupConfig = '/home/openach/backup-config/';
	static $backupInstall = '/home/openach/backup-install/';
	static $installFolder = '/home/www/openach/';
	static $repository = 'http://subversion.assembla.com/svn/openach/';
	static $yiiBase = '/home/www/yii/';
	static $dbUsername = 'openach';
	static $dbConf = array();
	static $apacheUser = 'www-data';
}

function info( $msg )
{
	echo "\t" . $msg . PHP_EOL;
}

function build_keys()
{
	$encryptionKey = substr( hash( 'sha256', openssl_random_pseudo_bytes( 65536 ) ), 0, 32 );
	$validationKey = substr( hash( 'sha256', openssl_random_pseudo_bytes( 65536 ) ), 0, 32 );
	$keyFile = Config::$installFolder.'protected/config/security.php';
	$fileContents = '<'.'?php'.PHP_EOL;
	$fileContents .= "return array(\n" .
		"		'cryptAlgorithm'        => 'rijndael-256',\n" .
		"		'encryptionKey'         => '$encryptionKey',\n" .
		"		'hashAlgorithm'         => 'sha1',\n" .
		"		'validationKey'         => '$validationKey',\n" .
		");\n";
	if ( file_exists( $keyFile ) )
	{
		info( 'Skipped creating a new security.php file, as one already exists.' );
		return;
	}
	file_put_contents( $keyFile, $fileContents );
	info( 'Created new keys and saved them into ' . $keyFile );
}

function setup_sqlite()
{
	$sourceDataPath = Config::$installFolder . "protected/data/openach.db.init_save";
	$destDataPath = Config::$installFolder . "protected/runtime/db/openach.db";

	if ( file_exists( $destDataPath ) )
	{
		info( 'Skipped initializing SQLite DB, as a file already exists at ' . $destDataPath );
		return;
	}
	exec("cp $sourceDataPath $destDataPath");

	info( 'Writing new db.conf file.' );
	$dbConfFile = Config::$installFolder.'protected/config/db.php';
	$fileContents = '<'.'?php'.PHP_EOL;
	$fileContents .= "return array(\n" .
		"		'connectionString'	=> 'sqlite:$destDataPath',\n" .
		"		'emulatePrepare'	=> true,\n" .
		"		'enableProfiling'	=> true,\n" .
		"		'initSQLs'		=> array( 'PRAGMA foreign_keys=ON' ),\n" .
		");\n";
	file_put_contents( $dbConfFile, $fileContents );

}

build_keys();
setup_sqlite();

