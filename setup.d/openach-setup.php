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

function confirm($options=array(),$autoconfirm=true)
{
	if ( $autoconfirm )
	{
		echo 'yes' . PHP_EOL;
		return true;
	}
	if ( ! $options || count($options) < 2 )
		$options = array('yes', 'no');
	while ( true )
	{
		echo ' (' . implode( '/', $options ) . '): ';
		$handle = fopen ("php://stdin","r");
		$line = fgets($handle);
		if(trim($line) == $options[0])
			return true;
		if(trim($line) == $options[1])
			return false;
	}
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
	file_put_contents( $keyFile, $fileContents );
	info( 'Created new keys and saved them into ' . $keyFile );
}

function reset_db_password()
{
	$chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
	$password = substr(str_shuffle($chars),0,10);

	if ( ! Config::$dbConf )
	{
		$dbPassResetCommand = "psql -c \"ALTER USER " . Config::$dbUsername . " WITH password '$password'\"";
		exec( "su - postgres -c '" . $dbPassResetCommand . "'" );
	}
	else
	{
		try
		{
			$db = new PDO( Config::$dbConf['connectionString'], Config::$dbUsername, Config::$dbConf['password'] );
			$sql = "ALTER USER openach WITH password '$password'";
			$db->exec($sql);
		}
		catch ( PDOException $e )	
		{	
			echo $e->getMessage();
			return;
		}
	}

	info( 'Writing new db.conf file.' );
	$dbFile = Config::$installFolder.'protected/config/db.php';
	$fileContents = '<'.'?php'.PHP_EOL;
	$fileContents .= "return array(\n" .
		"		'connectionString'	=> 'pgsql:host=localhost;port=5432;dbname=openach',\n" .
		"		'emulatePrepare'	=> true,\n" .
		"		'username'		=> '" . Config::$dbUsername . "',\n" .
		"		'password'		=> '$password',\n" .
		");\n";
	file_put_contents( $dbFile, $fileContents );
}

function backup_config()
{
	if ( ! file_exists( Config::$backupConfig ) )
		mkdir( Config::$backupConfig );
	// Backup all config files
	$date = new DateTime();
	$fileName = 'openach-config-backup-' . $date->format( 'Ymdhis' ) . '.tar';
	info( 'Backing up current configuration to ' . Config::$backupConfig . $fileName );

	try
	{
		$tar = new PharData( Config::$backupConfig . $fileName );
		$tar->buildFromDirectory( Config::$installFolder . 'protected/config/' );
	}
	catch (Exception $e)
	{
		echo $e->getMessage();
		echo 'Unable to back up current configuration.  Aborting!'. PHP_EOL;
		exit;
	}

	// Grab a copy of the last db settings before we move files around.
	$dbFile = Config::$installFolder.'protected/config/db.php';
	if ( file_exists( $dbFile ) )
		Config::$dbConf = require( Config::$installFolder.'protected/config/db.php' );
}

function backup_install()
{
	if ( ! file_exists( Config::$backupInstall ) )
		mkdir( Config::$backupInstall );
	// Backup all installation files
	$date = new DateTime();
	$fileName = 'openach-backup-' . $date->format( 'Ymdhis' ) . '.tar';
	info( 'Backing up current install to ' . Config::$backupInstall . $fileName );
	try
	{
		// Remove symlink as Phar does not play nice with them
		unlink( Config::$installFolder . 'yii' );
		$tar = new PharData( Config::$backupInstall . $fileName );
		$tar->buildFromDirectory( Config::$installFolder );
		$tar->compress(Phar::GZ);
		// Remove tar file - seems as though Phar does not do this
		unlink( Config::$backupInstall . $fileName );
		// Replace Yii link
		symlink( Config::$yiiBase, Config::$installFolder.'yii');
	}
	catch (Exception $e)
	{
		echo $e->getMessage();
		echo 'Unable to back up current install.  Aborting!'. PHP_EOL;
		exit;
	}

}

function upgrade( $release )
{
	$version = trim( file_get_contents( 'http://openach.com/webinstall/version/' . $release . '/' ) );
	if ( ! $version )
	{
		info( 'Unable to determine current ' . $release . ' version.  Skipping upgrade.' );
		return;
	}

	// Remove current installation
	info( 'Removing ' . Config::$installFolder );
	if ( trim( Config::$installFolder ) )
		passthru( 'rm -rf ' . Config::$installFolder );
	if ( $release == 'prod' )
		export_version( $version );
	else
		checkout_version( $version );
}

function export_version( $version )
{
	info('Exporting release from repository: ' .  Config::$repository.'/tags/'.$version);
	passthru( 'svn export ' . Config::$repository.'tags/'.$version.'/ ' . Config::$installFolder );
}

function checkout_version( $version )
{
	info('Exporting release from repository: ' .  Config::$repository.'/tags/'.$version);
	passthru( 'svn co ' . Config::$repository.'tags/'.$version.'/ ' . Config::$installFolder );
}

function setfacl_for_yii()
{
	echo PHP_EOL . "Setting file permissions required by Yii:" . PHP_EOL;
	foreach ( array( 'protected/runtime/', 'assets/' ) as $folder )
	{
		$path = Config::$installFolder . $folder;
		if ( file_exists( $path ) )
		{
			exec( 'chown -R ' . Config::$apacheUser . ':' . Config::$apacheUser . ' ' . $path );
		}
	}
}

function yiic_init_data( $command )
{
	if ( $command == 'fedachupdate' || $command == 'ofacupdate' )
	{
		passthru( Config::$installFolder . "/protected/openach $command reloadAll" );
	}
}

function setup_sqlite()
{
	$sourceDataPath = Config::$installFolder . "/protected/data/openach.db.init_save";
	$destDataPath = Config::$installFolder . "/protected/runtime/db/openach.db";
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

echo "This script will set up your OpenACH server appliance for the first time." . PHP_EOL;

//echo PHP_EOL . "Installing the latest production version of OpenACH.";
//upgrade('prod'); // Only if we don't already include the latest in the Dockerfile
build_keys();
//reset_db_password(); // Only for Postgres
setup_sqlite();

// The SQLite DB comes pre-loaded with this stuff.  We can update it when we're actually ready for it.
//echo PHP_EOL . "Loading the latest FedACH and Fedwire data.";
//yiic_init_data( 'fedachupdate' );
//echo PHP_EOL . "Loading the latest OFAC data.";
//yiic_init_data( 'ofacupdate' );

setfacl_for_yii();

echo PHP_EOL . "Setup complete.  Please refer to the Getting Started documentation at http://openach.com/books/getting-started for more information of what to do next." . PHP_EOL;




