# OpenACH CLI

OpenACH comes with a command line interface (CLI) that can be used to manage just about everything pertaining to the platform. Because it is used as the primary interface for OpenACH adminsitration, you will need to be comfortable with the Linux command line basics before proceeding. 

The CLI is located in the _protected/_ folder of your OpenACH install. You may notice that it is a symbolic link to the yiic command runner. Because OpenACH is built on top of the YII framework, it relies on the framework to run commands. You can substitute yiic for openach in any of the following examples. To see a list of available commands, run _./openach_ in the _protected/_ folder of your OpenACH install:

```
# cd /home/www/openach/protected/
# ./openach
Yii command runner (based on Yii v1.1.16)
Usage: ./openach  [parameters...]

The following commands are available:
 - altbatchbuilder
 - apiuser
 - bankplugin
 - batchbuilder
 - confirmationprocessor
 - cronnightly
 - encryptionutility
 - externalaccount
 - fedachupdate
 - filebuilder
 - hashindexer
 - message
 - migrate
 - ofacupdate
 - paymentprofile
 - paymentscheduler
 - phoneticindexer
 - profilesimulator
 - returnchangeprocessor
 - setup
 - shell
 - user
 - webapp

To see individual command help, use the following:
   ./openach help 
```

To get help on a specific command, use the help action. For instance, to see help for the user command:

```
# ./openach help user
Usage: ./openach user 
Actions:
    create --user_login=value --user_password=value --user_email_address=value --user_first_name=value --user_last_name=value
    changePassword --user_login=value --user_password=value
    view --user_id=value
    disable --user_id=value
    enable --user_id=value
    setup --user_id=value --name=value --identification=value --routing_number=value --account_number=value
```

## Getting Started
### Initializing Third Party Data
NOTE: If you are running the Docker image, or copied the distributed SQLite database file, you already have this data loaded. However, as there may be updates from time to time, you will want to reload this data before using in production.

OpenACH relies on a few third party data sources to populate its FedACH and OFAC-related tables. Thanks to the command line interface, loading and refreshing this data is simple:

First, load the FedACH directory:
```
# ./openach fedachupdate reloadAll
Opening file https://www.frbservices.org/EPaymentsDirectory/FedACHdir.txt for import.
Parsing file... (this may take a moment)
Processed 20019 lines.
Saved 20019 records.
Opening file https://www.frbservices.org/EPaymentsDirectory/fpddir.txt for import.
Parsing file... (this may take a moment)
Processed 8694 lines.
Saved 8694 records.
```
You can also update the OFAC lists, which are useful for implementing KYC/AML procedures on the OpenACH platform. Note that loading these lists can take a while:
```
# ./openach ofacupdate reloadAll
Opening file http://www.treasury.gov/ofac/downloads/sdn.ff for import.
Parsing file... (this may take a moment)
Processed 5738 lines.
Saved 5738 records.
Opening file http://www.treasury.gov/ofac/downloads/alt.ff for import.
Parsing file... (this may take a moment)
Processed 6855 lines.
Saved 6855 records.
Opening file http://www.treasury.gov/ofac/downloads/add.ff for import.
Parsing file... (this may take a moment)
Processed 10473 lines.
Saved 10473 records.
```

### Create New User
Once you have successfully installed OpenACH, the first step to a functional system is to create a user under which origination accounts can be set up.

```
# ./openach user create --user_login=johndoe --user_password=supersecret --user_email_address=johndoe@email.com --user_first_name=John --user_last_name=Doe
Creating new User...
User: 
	User ID:		ced64f44-1959-443d-a38f-0178f650050d
	Login:			johndoe
	First Name:		John
	Last Name:		Doe
	Status:			enabled
```

### Setup Origination Account
This new user can't do much without an origination account.   An origination account represents a banking relationship through which you will be processing your NACHA files.

While you could use the web interface to set up each piece individually, it's much quicker to use the user setup utility. Note that you will need to specify the User ID generated from the previous command.

The _identification_ field should be an EIN (Tax ID) for the business through which they are setting up the origination account. The _routing_number_ and _account_number_ fields are for the origination account at the bank where it was set up.  Feel free to use the sample values in the examples below for now if you would like to just try things out.  At the very least, you will need to use a valid routing number, as OpenACH validates this against the data loaded via the _fedAchUpdate_ command (see **Initializing Third-Party Data** above).

There are two methodologies that can be used to process your payments: with settlement or without settlement. If you send a debit ACH transaction to your processor and need the funds to move somewhere else after they land at your bank, you need to set up OpenACH with settlement. If you don't need to move the funds, or if your processor automatically moves the funds for you, you will set up OpenACH without settlement.

####Processing with Settlement
By default, the user setup command will build a settlement account for you using the routing and account number you provide. This can be updated after setup by editing the external account record created during setup. NOTE: When using OpenACH version 1.5 and higher, you can also specify the --plugin parameter to select the bank plugin you wish to use.

```
# ./openach user setup --user_id=ced64f44-1959-443d-a38f-0178f650050d --name="Test Originator" --identification=112358130 --routing_number=101000187 --account_number=1234567890
User: 
	Originator:		0e69c027-a9d4-466c-9f89-bbc47c8eb771
	Originator Info:	c38b6230-f8c9-45dc-9a86-5a32bc8d60d8
	Odfi Branch:	d38457a9-beff-4070-afc0-501c5b856f89
```

####Processing without Settlement
In cases where you don't need to move funds after processing the transactions, or if your ACH processor automatically moves the funds for you, you can set up your originator to process without settlement by using the --settle=0 flag on the setup command.

```
# ./openach user setup  --user_id=ced64f44-1959-443d-a38f-0178f650050d --name="Test Originator" --identification=112358130 --routing_number=101000187 --account_number=1234567890 --plugin=SagePay --settle=0
User: 
	Originator:		0e69c027-a9d4-466c-9f89-bbc47c8eb771
	Originator Info:	c38b6230-f8c9-45dc-9a86-5a32bc8d60d8
	Odfi Branch:	d38457a9-beff-4070-afc0-501c5b856f89
```

###Continuing Setup
If all goes well, you will get an ID for the Originator (the legal parent entity), the Originator Info (a particular origination account at a particular bank), and a Settlement Account (aka odfi_branch) that may or may not be linked to an External Account (depending on your choice of settlement above). It also created some Payment Types, and other odds and ends for you. Make a note of this information as you will need it later for configuring various aspects of OpenACH. If you forget it, you can always find it back using a few of the CLI user commands :

```
# ./openach user viewAll --user_login=johndoe
# ./openach user viewOriginators --user_id=5ae92cd5-5266-47ea-bb0d-0cfba5b95e38
User: 
	ID:		5ae92cd5-5266-47ea-bb0d-0cfba5b95e38
	Login:		johndoe
	First Name:		John
	Last Name:		Doe
	Status:			enabled

	Originator: 
		ID:		63845b3f-c71a-4478-93dd-86eff24123b6
		Name:		Test Originator

		Originator Info: 
			ID:		aa4361bf-5052-4be8-b993-728bedb20632
			Name:		Test Originator

		Odfi Branch: 
			ID:		d38457a9-beff-4070-afc0-501c5b856f89
			Name:		Test Originator House Account
			Plugin:		SagePay
```
Earlier versions of OpenACH don't include the Odfi Branch (Settlement Account) information when inspecting the originator. The simplest way to find it is to look in the database:
```
# sqlite3 runtime/db/openach.db 
SQLite version 3.8.2 2013-12-06 14:53:30
Enter ".help" for instructions
Enter SQL statements terminated with a ";"
sqlite> SELECT originator_info_odfi_branch_id FROM originator_info WHERE originator_info_originator_id = '63845b3f-c71a-4478-93dd-86eff24123b6'
d38457a9-beff-4070-afc0-501c5b856f89
sqlite> .quit
```

###Bank Plugins
By default, your account is configured with the Manual plugin, which produces NACHA files that you can manually transfer to your bank however you wish. You are free to configure your origination account to use any included plugin, or even develop your own. The OpenACH CLI includes a utility to manage the plugins. You will need to know the odfi_branch_id of your settlement account (see above).

NOTE! Bank plugin management via the CLI isn't included in earlier versions of OpenACH. You will need version 1.5 or higher. The latest Docker image typically has the newest version, so you should be good.

```
./openach bankPlugin

Usage: ./openach bankplugin 
Actions:
    register --class=value
    load --odfi_branch_id=value
    setPlugin --odfi_branch_id=value --plugin=value

    updateTransferConfig --odfi_branch_id=value --newConfig=value
    test --odfi_branch_id=value
```

###Register a Bank Plugin
In order to use a plugin, it must first be registered. The plugin class files live under the application directory in protected/vendors/OpenACH/nacha/Banks/. Beginning with version 1.5, plugin classes include ManualConfig, USBankConfig, WellsFargoConfig, and SagePayConfig. OpenACH 1.5 and newer come with all these plugins pre-registered/enabled. If you have installed a newer plugin on an older code base, you will need to register it, as it won't function until it has been registered. To enable OpenACH to use any plugin, simply run the following command, where CLASS_NAME is the full class name of the bank plugin:

```
# ./openach bankPlugin register --class=CLASS_NAME
```

###Assign and Configure the Bank Plugin
Use the bankPlugin setPlugin command to assign the Odfi Branch (Settlement Account) a bank plugin to use for processing. Unlike the register command, you will refer to the plugin by its ID rather than the class name of the bank plugin class. For instance, "SagePay", "USBank", "WellsFargo" or "Manual" (leaving off the "Config" from the class name). The setPlugin command will return a set of JSON formatted parameters. If this is your first time using this plugin for your Odfi Branch, the values will be the plugin defaults, otherwise they will be values from the last time you used the plugin.

```
# ./openach bankPlugin setPlugin --odfi_branch_id=d38457a9-beff-4070-afc0-501c5b856f89 --plugin=SagePay
Using Bank Plugin: SagePay
Transfer Configuration:
{"prod_host":"ftp.eftchecks.com","prod_port":"22","test_host":"ftp.eftchecks.com","test_port":"22","user":"","password":"","key":"","outbound_path":"Incoming\/","outbound_file":"{{id}}","confirm_path":"Outgoing\/","confirm_file":"*_File_Summary_*.csv","return_path":"Outgoing\/","return_file":"*_Merchant_Change_Report_*.csv"}

Record Configuration:
null
```
Next, update the plugin config specific to your situation. Most of the plugins require user and password to be updated in order to properly transfer files to the processor. Use JSON formatted parameter list with the bankPlugin updateTransferConfig command to specify the parameters you want to update.

```
# ./openach bankPlugin updateTransferConfig --odfi_branch_id=d38457a9-beff-4070-afc0-501c5b856f89 --newConfig='{"user":"testuser","password":"testpassword"}'
```
You can easily verify your changes took effect using the bankPlugin view command:

```
# ./openach bankPlugin view --odfi_branch_id=d38457a9-beff-4070-afc0-501c5b856f89
Using Bank Plugin: SagePay
Transfer Configuration:
{"prod_host":"ftp.eftchecks.com","prod_port":"22","test_host":"ftp.eftchecks.com","test_port":"22","user":"testuser","password":"testpassword","key":"","outbound_path":"Incoming\/","outbound_file":"{{id}}","confirm_path":"Outgoing\/","confirm_file":"*_File_Summary_*.csv","return_path":"Outgoing\/","return_file":"*_Merchant_Change_Report_*.csv"}

Record Configuration:
null
```

If your ACH processor requires you to override specific fields, and assuming you have an OpenACH install that calls the odfiBranch->getBankConfig()->beforeRecordSave( $record ) hook during file building (e.g. newer versions of the AltBatchBuilderCommand, or custom code), you can configure these overrides using the bankPlugin updateRecordConfig command. The beforeRecordSave() method will load the record config, look for a matching class name, and set the specified fields to the given values. Assuming the hooks are in place, the following would set the header discretionary data field on the PPD batch record, and the immediate origin name on the file record.

```
# ./openach bankPlugin updateRecordConfig --odfi_branch_id=d38457a9-beff-4070-afc0-501c5b856f89 --newConfig='{"AchBatchPPD":{"ach_batch_header_discretionary_data":1234567},"AchFile":{"ach_file_header_immediate_origin_name":"WELLS FARGO"}}'
```

You can verify your changes took effect using the bankPlugin view command.

###Where to Go From Here
At this point, you have an origination account set up and ready to add payment profiles and payment schedules. You can log into OpenACH by pointing your browser at the server where you have it installed (http://localhost/ for instance). Note the web interface is mainly for reference. Most everything you will be doing with OpenACH will be accomplished by integrating using the OpenACH API.

###Integrating with OpenACH
If you have other systems that you want to use with OpenACH, adding payment processing to existing or new applications, integration with a website, etc., you will want to set up an API user for the origination account that you created above. NOTE: The UUIDs used below should be replaced with the ones you saw when setting up your user in the steps above.

```
# ./openach apiuser create --user_id=ced64f44-1959-443d-a38f-0178f650050d --originator_info_id=c38b6230-f8c9-45dc-9a86-5a32bc8d60d8
Creating new API User...
API User: 
	User ID:		ced64f44-1959-443d-a38f-0178f650050d
	Originator Info ID:	c38b6230-f8c9-45dc-9a86-5a32bc8d60d8
	Api Token:		veMnAoCAaPJr9NUmJ9KkD2Oz5hO3rY70A1VSnc1mBq2
	Api Key:		eTqgmbqukjEs13V942heirDxmWbKNnJgAcocvJ4wCGN
	Status:			enabled
```
For more information on integrating with the OpenACH API, please refer to the Integrating with OpenACH guide (https://openach.com/books/integrating-openach/integrating-openach).



