#**************************************************************************************************#
#FEATURE                : <DCR> 
#FEATURE ENGINEER       : <DCR_2_0 :  DCR Support for Cisco/RBP Protocol Interface>
#AUTOMATION ENGINEER    : <tttha>
#**************************************************************************************************#

our %TESTBED;
our $TESTSUITE;

package QATEST::DSC::DCR_2_0::ADQ_1411::ADQ_1411; 

use strict;
use Tie::File;
use File::Copy;
use Cwd qw(cwd);
use Storable; # store and retrieve hash

use String::Random;
#********************************* LIST OF LIBRARIES***********************************************#

use ATS; 
use SonusQA::Utils qw (:all);
use Data::Dumper;
#**************************************************************************************************#

use Log::Log4perl qw(get_logger :levels);
my $logger = Log::Log4perl->get_logger(__PACKAGE__);

##################################################################################
#  DSC::TEMPLATE                                                                  #
##################################################################################
#  This package tests for the DSC.                                               #
##################################################################################

##################################################################################
# SETUP                                                                          #
##################################################################################
my $dir = cwd;
my ($sec,$min,$hour,$mday,$mon,$year,$wday, $yday,$isdst) = localtime(time);
my $datestamp = sprintf "%4d%02d%02d-%02d%02d%02d", $year+1900,$mon+1,$mday,$hour,$min,$sec;
my ($ses_Selenium,$ses_Selenium1, $ses_CLI1, $ses_CLI2, $ses_ATS);


my $NA_50 = '50';
my $DRE_50 = '50';
my $VNODE = '1.1.1';
# Required Testbed elements for this package

my %REQUIRED = ( 
        "SELENIUM" => [1],
        "C20" => [1]
               );

################################################################################
# COMMON VARIABLES USED IN THE SUITE Defined HERE#
################################################################################

# Login to web

my $dcr_ip = $TESTBED{"c20:1:ce0:hash"}->{"MGMTNIF"}->{1}->{"IP"};
my $dcr_ip_128 = $TESTBED{"c20:2:ce0:hash"}->{"MGMTNIF"}->{1}->{"IP"};
my $dcr_username = "root";
my $dcr_passwd = $TESTBED{"c20:1:ce0:hash"}->{"LOGIN"}->{1}->{"PASSWD"};
my $url = "https://".$dcr_ip;
my $url_128 = "https://".$dcr_ip_128;


# Selenium source

my $seleniumSource = $TESTBED{"selenium:1:ce0:hash"}->{"NODE"}->{1}->{"BASEPATH"};
my $imagePath = $TESTBED{"selenium:1:ce0:hash"}->{"NODE"}->{1}->{"IMAGE"};
my $browser = "chrome";

##################################################################################
sub configured {

    # Check configured resources match REQUIRED
    if ( SonusQA::ATSHELPER::checkRequiredConfiguration ( \%REQUIRED, \%TESTBED ) ) {
        $logger->info(__PACKAGE__ . ": Found required devices in TESTBED hash"); 
    }else{
        $logger->error(__PACKAGE__ . ": Could not find required devices in TESTBED hash"); 
        return 0;
	}
}

sub cleanup {
    my $subname = "ADQ_1411_cleanup";
    $logger->debug(__PACKAGE__ ." . $subname . DESTROYING OBJECTS");
    if (defined $ses_Selenium) {
    	$ses_Selenium->quit();
        $ses_Selenium->DESTROY();
        undef $ses_Selenium;
    }
	if (defined $ses_CLI1) {
        $ses_CLI1->DESTROY();
        undef $ses_CLI1;
    }
	if (defined $ses_CLI2) {
        $ses_CLI2->DESTROY();
        undef $ses_CLI2;
    }
	if (defined $ses_ATS) {
        $ses_ATS->DESTROY();
        undef $ses_ATS;
    }
	if (defined $ses_Selenium1) {
    	$ses_Selenium1->quit();
        $ses_Selenium1->DESTROY();
        undef $ses_Selenium1;
    }
    return 1;
}

sub checkResult {
    my ($tcid, $result) = (@_);
    my $subname = "ADQ_1411_checkResult";
    $logger->debug(__PACKAGE__ . ".$tcid: Test result : $result");
    if ($result) { 
        $logger->debug(__PACKAGE__ . "$tcid  Test case passed ");
            SonusQA::ATSHELPER::printPassTest($tcid);
            return 1;
    } else {
        $logger->debug(__PACKAGE__ . "$tcid  Test case failed ");
            SonusQA::ATSHELPER::printFailTest($tcid);
            return 0;
    }
}

sub loginAndAccessDCR {
	my ($session) = (@_);

	### Input username & password
    my $textbox_Username = "//input[\@name='user']";
    my $value_Username = $dcr_username;
    unless ($session->inputText(-xPath => $textbox_Username, -text => $value_Username)) {
        $logger->error(__PACKAGE__ . ": Failed to send username '$value_Username' to username textbox" );
        print FH "STEP: Input username '$value_Username' - FAIL \n";
        return 0;
    } else {
        print FH "STEP: Input username '$value_Username' - PASS \n";
    }
    
    my $textbox_passwd = "//input[\@name='password']";
    my $value_passwd = $dcr_passwd;
    unless ($session->inputText(-xPath => $textbox_passwd, -text => $value_passwd)) {
        $logger->error(__PACKAGE__ . ": Failed to send password '$value_passwd' to password textbox" );
        print FH "STEP: Input password '$value_passwd' - FAIL \n";
        return 0;
    } else {
        print FH "STEP: Input password '$value_passwd' - PASS \n";
    }

    my $button_login = "//input[\@type='submit']";
    unless ($session->clickElement(-xPath => $button_login)) {
        $logger->error(__PACKAGE__ . ": Failed to click 'Login' button" );
        print FH "STEP: Click 'Login' button - FAIL \n";
        return 0;
    } else {
        print FH "STEP: Click 'Login' button - PASS \n";
    }
    
	my $logout = "//a[text()='Logout']";
	unless ($session->inspect(-action => "isdisplayed", -xPath => $logout)) {
        $logger->error(__PACKAGE__ . ": Failed to login with username: '$value_Username' and password:  '$value_passwd'" );
        print FH "STEP: Login failed - FAIL \n";
        return 0;
    } else {
        print FH "STEP: Login successfully - PASS \n";
    }

	### Click to DCR item in Applications_menu
	my $dcrItem = "//ul[\@id='Applications_menu']/li/a[text()='DCR']";    
    unless ($session->clickElement(-xPath => $dcrItem)) {
        $logger->error(__PACKAGE__ . ": Failed to click 'DCR Item'" );
        print FH "STEP: Click 'DCR Item' - FAIL \n";
        return 0;
    } else {
        print FH "STEP: Click 'DCR Item' - PASS \n";
    }
	

	$logger->debug(__PACKAGE__ . ": Login DSC CMU and access DCR Item successfully");
	return 1;
}

sub login {
	my ($session) = (@_);

	### Input username & password
    my $textbox_Username = "//input[\@name='user']";
    my $value_Username = $dcr_username;
    unless ($session->inputText(-xPath => $textbox_Username, -text => $value_Username)) {
        $logger->error(__PACKAGE__ . ": Failed to send username '$value_Username' to username textbox" );
        print FH "STEP: Input username '$value_Username' - FAIL \n";
        return 0;
    } else {
        print FH "STEP: Input username '$value_Username' - PASS \n";
    }
    
    my $textbox_passwd = "//input[\@name='password']";
    my $value_passwd = $dcr_passwd;
    unless ($session->inputText(-xPath => $textbox_passwd, -text => $value_passwd)) {
        $logger->error(__PACKAGE__ . ": Failed to send password '$value_passwd' to password textbox" );
        print FH "STEP: Input password '$value_passwd' - FAIL \n";
        return 0;
    } else {
        print FH "STEP: Input password '$value_passwd' - PASS \n";
    }

    my $button_login = "//input[\@type='submit']";
    unless ($session->clickElement(-xPath => $button_login)) {
        $logger->error(__PACKAGE__ . ": Failed to click 'Login' button" );
        print FH "STEP: Click 'Login' button - FAIL \n";
        return 0;
    } else {
        print FH "STEP: Click 'Login' button - PASS \n";
    }
    
	my $logout = "//a[text()='Logout']";
	unless ($session->inspect(-action => "isdisplayed", -xPath => $logout)) {
        $logger->error(__PACKAGE__ . ": Failed to login with username: '$value_Username' and password:  '$value_passwd'" );
        print FH "STEP: Login failed - FAIL \n";
        return 0;
    } else {
        print FH "STEP: Login successfully - PASS \n";
    }    

    $logger->debug(__PACKAGE__ . ": Login DSC CMU successfully");
}

sub cleanup_mtp3 {
    my ($TL_sesson) = (@_);
    ## Cleanup VNODE
    unless(grep/(Already inactive|:"Invalid AID";|:SET-VND:CTAG:COMPLD;)/,$TL_sesson->execCmd("SET-VND::$NA_50-$VNODE:CTAG:::DEACT;")) {
        $logger->error(__PACKAGE__ . ": Failed to Disable VND to clean up before testing by command 'SET-VND::$NA_50-$VNODE:CTAG:::DEACT;'  " );
        return 0;
    }  
    unless(grep/(:"Invalid AID";|:DLT-VND:CTAG:COMPLD;)/,$TL_sesson->execCmd("DLT-VND::$NA_50-$VNODE:CTAG;")) {
        $logger->error(__PACKAGE__ . ": Failed to Disable VND to clean up before testing by command 'DLT-VND::$NA_50-$VNODE:CTAG;'  " );
        return 0;
    }

    #cleanup M2PA-Link 
    unless(grep/(:"Invalid AID";|COMPLD|deactivated)/,$TL_sesson->execCmd("DLT-SLK::50-51.51.51-0:CTAG;")) {
        $logger->error(__PACKAGE__ . ": Failed to Disable M2PA-Link to clean up before testing by command 'DLT-SLK::50-51.51.51-0:CTAG;' " );
        return 0;
    }  
    # clean Route
    unless(grep/(already inactive|:"Invalid AID";|COMPLD)/,$TL_sesson->execCmd("SET-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG:::RESETSTATE;")) {
        $logger->error(__PACKAGE__ . ": Failed to Disable Route to clean up before testing by command 'SET-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG:::RESETSTATE;' " );
        return 0;
    } 
    unless(grep/(:"Invalid AID";|COMPLD)/,$TL_sesson->execCmd("DLT-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ": Failed to Disable Route to clean up before testing by command 'DLT-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG;' " );
        return 0;
    }  
      
    #cleanup LS Link Selection
    unless(grep/(already inactive|:"Invalid AID";|COMPLD|deactivated)/,$TL_sesson->execCmd("SET-SLK::50-51.51.51-5:CTAG:::DEACT:LS;")) {
        $logger->error(__PACKAGE__ . ": Failed to Disable LS Link Selection to clean up before testing by command 'SET-SLK::50-51.51.51-5:CTAG:::DEACT:LS;' " );
        return 0;
    } 
    unless(grep/(:"Invalid AID";|COMPLD)/,$TL_sesson->execCmd("DLT-SLK::50-51.51.51-5:CTAG;")) {
        $logger->error(__PACKAGE__ . ": Failed to Disable LSL to clean up before testing by command 'DLT-SLK::50-51.51.51-5:CTAG;' " );
        return 0;
    } 
    # cleanup ATM LINK
    unless(grep/(already inactive|:"Invalid AID";|COMPLD|deactivated)/,$TL_sesson->execCmd("SET-SLK::50-51.51.51-0:CTAG:::DEACT:ATM;")) {
        $logger->error(__PACKAGE__ . ": Failed to Disable ATM LINK to clean up before testing by command ' SET-SLK::50-51.51.51-0:CTAG:::DEACT:ATM;' " );
        return 0;
    } 
    unless(grep/(:"Invalid AID";|COMPLD|deactivated)/,$TL_sesson->execCmd("DLT-SLK::50-51.51.51-0:CTAG;")) {
        $logger->error(__PACKAGE__ . ": Failed to Disable ATM LINK to clean up before testing by command 'DLT-SLK::50-51.51.51-0:CTAG;' " );
        return 0;
    }  
    #cleanup Annex A link
    unless(grep/(already inactive|:"Invalid AID";|COMPLD|deactivated)/,$TL_sesson->execCmd("SET-SLK::50-51.51.51-0:CTAG:::DEACT:ANNEXA;")) {
        $logger->error(__PACKAGE__ . ": Failed to Disable Annex A link to clean up before testing by command 'SET-SLK::50-51.51.51-0:CTAG:::DEACT:ANNEXA;' " );
        return 0;
    } 
    unless(grep/(:"Invalid AID";|COMPLD)/,$TL_sesson->execCmd("DLT-SLK::50-51.51.51-0:CTAG;")) {
        $logger->error(__PACKAGE__ . ": Failed to Disable Annex A link to clean up before testing by command 'DLT-SLK::50-51.51.51-0:CTAG;' " );
        return 0;
    }
    #cleanup Generic Link
    unless(grep/(:"Invalid AID";|COMPLD)/,$TL_sesson->execCmd("SET-SLK::50-51.51.51-0:CTAG:::DEACT:GENERIC;")) {
        $logger->error(__PACKAGE__ . ": Failed to Disable Generic LINK to clean up before testing by command 'SET-SLK::50-51.51.51-0:CTAG:::DEACT:GENERIC;' " );
        return 0;
    } 
    unless(grep/(:"Invalid AID";|COMPLD)/,$TL_sesson->execCmd("DLT-SLK::50-51.51.51-0:CTAG;")) {
        $logger->error(__PACKAGE__ . ": Failed to Disable Generic LINK to clean up before testing by command 'DLT-SLK::50-51.51.51-0:CTAG;' " );
        return 0;
    } 

    # Cleanup Linkset
    unless(grep/(:"Invalid AID";|COMPLD)/,$TL_sesson->execCmd("DLT-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ": Failed to Disable Linkset to clean up before testing by command 'DLT-LS::50-51.51.51:CTAG;' " );
        return 0;
    }  

    ## Cleanup Routeset
    unless(grep/(already inactive|:"Invalid AID";|COMPLD)/,$TL_sesson->execCmd("SET-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG:::DEACT;")) {
        $logger->error(__PACKAGE__ . ": Failed to Disable Routeset to clean up before testing by command 'SET-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG:::DEACT;' " );
        return 0;
    } 
    unless(grep/(:"Invalid AID";|COMPLD)/,$TL_sesson->execCmd("DLT-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;")) {
        $logger->error(__PACKAGE__ . ": Failed to Disable Routeset to clean up before testing by command 'DLT-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;' " );
        return 0;
    }  
    ## Cleanup PC Mapping
    unless(grep/(:"Invalid AID";|:DLT-PCMAP:CTAG:COMPLD;)/,$TL_sesson->execCmd("DLT-PCMAP::50-Autotest_mapping:CTAG;")) {
        $logger->error(__PACKAGE__ . ": Failed to Disable PC Mapping to clean up before testing by command 'DLT-PCMAP::50-Autotest_mapping:CTAG;' " );
        return 0;
    }  
    ## Cleanup migration record
    unless(grep/(:"Invalid AID";|:DLT-MIGREC:CTAG:COMPLD;)/,$TL_sesson->execCmd(" DLT-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG;")) {
        $logger->error(__PACKAGE__ . ": Failed to Disable PC Mapping to clean up before testing by command 'DLT-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG;' " );
        return 0;
    }  
    ## Cleanup NA
    unless(grep/(already inactive|:"Invalid AID";|:SET-NA:CTAG:COMPLD;)/,$TL_sesson->execCmd("SET-NA::50:CTAG:::DEACT;")) {
        $logger->error(__PACKAGE__ . ": Failed to Deactive NA by command 'SET-NA::50:CTAG:::DEACT;'  " );
        return 0;
    }
    unless(grep/(:"Invalid AID";|:DLT-NA:CTAG:COMPLD;)/,$TL_sesson->execCmd("DLT-NA::50:CTAG;")) {
        $logger->error(__PACKAGE__ . ": Failed to Clean up by command 'DLT-NA::50:CTAG;'  " );
        return 0;
    }      
}

##################################################################################


# TESTS                                                                          #
##################################################################################

our @TESTCASES = (
					# "ADQ_1411_Auto_MTP3_01",
                    # "ADQ_1411_Auto_MTP3_02",
                    # "ADQ_1411_Auto_MTP3_03",
                    # "ADQ_1411_Auto_MTP3_04",
                    # "ADQ_1411_Auto_MTP3_05",
                    # "ADQ_1411_Auto_MTP3_06",
                    # "ADQ_1411_Auto_MTP3_07",
                    # "ADQ_1411_Auto_MTP3_08",
                    # "ADQ_1411_Auto_MTP3_09",
                    # "ADQ_1411_Auto_MTP3_10",
                    # "ADQ_1411_Auto_MTP3_11",
                    # "ADQ_1411_Auto_MTP3_12",
                    # "ADQ_1411_Auto_MTP3_13",
                    # "ADQ_1411_Auto_MTP3_14",
                    # "ADQ_1411_Auto_MTP3_16",
                    # "ADQ_1411_Auto_MTP3_17",
                    # "ADQ_1411_Auto_MTP3_18",
                    # "ADQ_1411_Auto_MTP3_19",
                    # "ADQ_1411_Auto_MTP3_20",
                    # "ADQ_1411_Auto_MTP3_21",
                    # "ADQ_1411_Auto_MTP3_22",
                    # "ADQ_1411_Auto_MTP3_23",
                    # "ADQ_1411_Auto_MTP3_24",
                    # "ADQ_1411_Auto_MTP3_25",
                    # "ADQ_1411_Auto_MTP3_26",
                    # "ADQ_1411_Auto_MTP3_27",
                    # "ADQ_1411_Auto_MTP3_28",
                    # "ADQ_1411_Auto_MTP3_29",
                    # "ADQ_1411_Auto_MTP3_30",
                    # "ADQ_1411_Auto_MTP3_31",
                    # "ADQ_1411_Auto_MTP3_32",
                    # "ADQ_1411_Auto_MTP3_33",
                    # "ADQ_1411_Auto_MTP3_34",
                    # "ADQ_1411_Auto_MTP3_35",
                    # "ADQ_1411_Auto_MTP3_36",
                    # "ADQ_1411_Auto_MTP3_37",
                    # "ADQ_1411_Auto_MTP3_38",
                    # "ADQ_1411_Auto_MTP3_39",
                    # "ADQ_1411_Auto_MTP3_40",
                    # "ADQ_1411_Auto_MTP3_41",
                    # "ADQ_1411_Auto_MTP3_42",
                    # "ADQ_1411_Auto_MTP3_43",
                    # "ADQ_1411_Auto_MTP3_44",
                    # "ADQ_1411_Auto_MTP3_45",
                    # "ADQ_1411_Auto_MTP3_46",
                    # "ADQ_1411_Auto_MTP3_47",
                    # "ADQ_1411_Auto_MTP3_48",
                    # "ADQ_1411_Auto_MTP3_49",
                    # "ADQ_1411_Auto_MTP3_50",
                    # "ADQ_1411_Auto_MTP3_51",
                    # "ADQ_1411_Auto_MTP3_52",
                    # "ADQ_1411_Auto_MTP3_53",
                    # "ADQ_1411_Auto_MTP3_54",
                    # "ADQ_1411_Auto_MTP3_55",
                    # "ADQ_1411_Auto_MTP3_56",
                    # "ADQ_1411_Auto_MTP3_57",
                    # "ADQ_1411_Auto_MTP3_58",
                    # "ADQ_1411_Auto_MTP3_59",
                    # "ADQ_1411_Auto_MTP3_60",
                    # "ADQ_1411_Auto_MTP3_61",
                    # "ADQ_1411_Auto_MTP3_62",
                    # "ADQ_1411_Auto_MTP3_63",
                    # "ADQ_1411_Auto_MTP3_64",
                    # "ADQ_1411_Auto_MTP3_65",
                    # "ADQ_1411_Auto_MTP3_66",
                    # "ADQ_1411_Auto_MTP3_67",
                    # "ADQ_1411_Auto_MTP3_68",
                    # "ADQ_1411_Auto_MTP3_69",
                    # "ADQ_1411_Auto_MTP3_70",
                    # "ADQ_1411_Auto_MTP3_71",
                    # "ADQ_1411_Auto_MTP3_72",
                    # "ADQ_1411_Auto_MTP3_73",
                    # "ADQ_1411_Auto_MTP3_74",
                    # "ADQ_1411_Auto_MTP3_75",
                    # "ADQ_1411_Auto_MTP3_76",
                    # "ADQ_1411_Auto_MTP3_77",
                    # "ADQ_1411_Auto_MTP3_78",
                    # "ADQ_1411_Auto_MTP3_79",
                    # "ADQ_1411_Auto_MTP3_80",
                    # "ADQ_1411_Auto_MTP3_81",
                    # "ADQ_1411_Auto_MTP3_82",
                    # "ADQ_1411_Auto_MTP3_83",
                    # "ADQ_1411_Auto_MTP3_84",

				);
				
##################################################################################
sub runTests {
##################################################################################

    unless ( &configured ) {
        $logger->error(__PACKAGE__ . ": Could not configure for test suite ".__PACKAGE__); 
        return 0;
    }
		$logger->debug(__PACKAGE__ . " ======: before Opening Harness");
	my $harness;
	unless($harness = SonusQA::HARNESS->new( -suite => __PACKAGE__, -release => "$TESTSUITE->{TESTED_RELEASE}", -variant => $TESTSUITE->{TESTED_VARIANT}, -build => $TESTSUITE->{BUILD_VERSION}, -path => "ats_repos/test/setup/work")){ # Use this for real SBX Hardware.
		$logger->error(__PACKAGE__ . ": Could not create harness object");
		return 0;
	}
    $logger->debug(__PACKAGE__ . " ======: Opened Harness"); 

    my @tests_to_run;

    # If an array is passed in use that. If not run every test.
    if ( @_ ) {
        @tests_to_run = @_;
    }
    else {
        @tests_to_run = @TESTCASES;
    }

    $harness->{SUBROUTINE}= 1;    
    $harness->runTestsinSuite( @tests_to_run ); 
    
}

##################################################################################
# +------------------------------------------------------------------------------+
# |                                                                  |
# +------------------------------------------------------------------------------+
# |   TMSID = ""                                                             |
# +------------------------------------------------------------------------------+
# +------------------------------------------------------------------------------+
sub ADQ_1411_Auto_MTP3_01 { #Verify MTP3 NA Manager 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_01");
    my $sub_name = "ADQ_1411_Auto_MTP3_01";
	my $tcid = "ADQ_1411_Auto_MTP3_01";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
    #1. Login to the CLI lab 128 
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}
    $ses_CLI1->{conn}->prompt('/PTI_TL1>/');
    #2. Run command: "telnet localhost 6669" 
    unless(grep /Connected to localhost/,$ses_CLI1->execCmd("telnet localhost 6669")){
       $logger->error(__PACKAGE__ . ": Could not Execute command: telnet localhost 6669");
       print FH "STEP: Execute command 'telnet localhost 6669' - FAILED\n";
       $result = 0;              
    } else {
       print FH "STEP: Execute command 'telnet localhost 6669' - PASSED\n";
    }
    #3. Run command: "act-user::root:::y6U&i8o9;" to login the TL1 mode
    unless(grep /COMPLD/,$ses_CLI1->execCmd("act-user::root:::y6U&i8o9;")){
       $logger->error(__PACKAGE__ . ": Could not Execute command:act-user::root:::y6U&i8o9;");
       print FH "STEP: Execute command 'act-user::root:::y6U&i8o9;' - FAILED\n";
       $result = 0;              
    } else {
       print FH "STEP: Execute command 'act-user::root:::y6U&i8o9;' - PASSED\n";
    }
    #4. Add cmd: " VFY-NAMGR:::[CTAG];"
    my @outputCmd;
    unless(grep /:VFY-NAMGR:CTAG:COMPLD/,@outputCmd = $ses_CLI1->execCmd("VFY-NAMGR:::[CTAG];")){
       $logger->error(__PACKAGE__ . ": Could not Execute command: VFY-NAMGR:::[CTAG];");
       print FH "STEP: Execute command 'VFY-NAMGR:::[CTAG];' - FAILED\n";
       $result = 0;              
    } else {
       print FH "STEP: Execute command 'VFY-NAMGR:::[CTAG];' - PASSED\n";
    }
    my $value;
    foreach (@outputCmd){
        if ($_ =~ /(.*\t:::).*/){
            $value = $_;
            last;
        }
    }
    $logger->debug(__PACKAGE__ . "Values: $value");
    #my @array = split (",", $_);
    #	:::NA_DBG_LEVEL=1,LDL_DBG_LEVEL=2,TELEDIAG=LOGGED,MSUQ=200000,TIME_CONG1=500 ms,TIME_CONG2=900 ms,TIME_CONG3=1200 ms,
    
    
    my (@array, $NA_DBG_LEVEL, $LDL_DBG_LEVEL, $TELEDIAG, $MSUQ, $TIME_CONG1, $TIME_CONG2, $TIME_CONG3);
    @array = $value;
    foreach(@array){
        if ($_ =~ /.*NA_DBG_LEVEL=(\d),LDL_DBG_LEVEL=(\d),TELEDIAG=(\w+),MSUQ=(\d+),TIME_CONG1=(\d+\s\w+),TIME_CONG2=(\d+\s\w+),TIME_CONG3=(\d+\s\w+),/){
            $NA_DBG_LEVEL = $1;
            $LDL_DBG_LEVEL = $2;
            $TELEDIAG = $3;
            $MSUQ = $4;
            $TIME_CONG1 = $5;
            $TIME_CONG2 = $6;
            $TIME_CONG3 = $7;    
            last;
        }
    }
    $logger->debug(__PACKAGE__ . " NA_DBG_LEVEL: $NA_DBG_LEVEL");
    $logger->debug(__PACKAGE__ . " LDL_DBG_LEVEL: $LDL_DBG_LEVEL");
    $logger->debug(__PACKAGE__ . " TELEDIAG: $TELEDIAG");
    $logger->debug(__PACKAGE__ . " MSUQ: $MSUQ");
    $logger->debug(__PACKAGE__ . " LDL_DBG_LEVEL: $TIME_CONG1");
    $logger->debug(__PACKAGE__ . " LDL_DBG_LEVEL: $TIME_CONG2");
    $logger->debug(__PACKAGE__ . " LDL_DBG_LEVEL: $TIME_CONG3");
    
    # Go to the Web UI
    #---get user, pass on TMS
    unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
    #--call function initialize() to launch the browser
    my ($sessionId,$localUrl);
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Launch the $url not success" );
        print FH "STEP: Launch the '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the '$url' - PASS \n";
    }
    #--login 
    unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    #--click MTP3 tab
	my $xpath_mtp3 = "//a[contains (text(), 'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $xpath_mtp3)) {
        $logger->error(__PACKAGE__ . ".$tcid: Faild to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #--tab xpath_debug_level_configuration
    my $xpath_debug_level_configuration = "//div[contains (text(),'Debug Level Configuration')]";
    unless ($ses_Selenium->clickElement(-xPath => $xpath_debug_level_configuration)) {
        $logger->error(__PACKAGE__ . ".$tcid: Click 'Debug Level Configuration' tab not success" );
        print FH "STEP: Click 'Debug Level Configuration' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'Debug Level Configuration' tab - PASS \n";
    }  
    #--call function inspect() to define an element is exist/not exist/isDisplayed/isEnabled/isSelected
    #-- get value of NA Debug Level (=1)
    my $xpath_na_debug_level = "//div[text()='NA Debug Level']/following-sibling::div//input[\@value='$NA_DBG_LEVEL']";
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $xpath_na_debug_level)) {
        $logger->error(__PACKAGE__ . ".$tcid: Faild to Verify the NA Debug Level" );
        print FH "STEP: Verify the NA Debug Level - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the NA Debug Level - Pass \n";
    }

    my $xpath_ldl_debug_level = "//div[contains (text(), 'LDL Debug Level')]/following-sibling::div//input[\@value='$LDL_DBG_LEVEL']";
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $xpath_ldl_debug_level)) {
        $logger->error(__PACKAGE__ . ".$tcid: Faild to Verify the LDL Debug Level" );
        print FH "STEP: Verify the LDL Debug Level - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the LDL Debug Level - Pass \n";
    }
    #$TELEDIAG, $MSUQ, $TIME_CONG1, $TIME_CONG2, $TIME_CONG3
    my $xpath_tetlediag ="//div[contains (text(), 'Telemetry Diagnostics')]/following-sibling::div//option[\@value='$TELEDIAG']";
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $xpath_tetlediag)) {
        $logger->error(__PACKAGE__ . ".$tcid: Faild to Verify the NA Debug Level" );
        print FH "STEP: Verify the Telemetry Diagnostics - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the Telemetry Diagnostics - Pass \n";
    }

    #-----SNM-DRE Queueing Configuration
    my $xpath_snm_dre_que_cfg = "//a[contains(text(),'SNM-DRE Queueing Configuration')]";
    unless ($ses_Selenium->clickElement(-xPath => $xpath_snm_dre_que_cfg)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'SNM-DRE Queueing Configuration' tab" );
        print FH "STEP: Click 'SNM-DRE Queueing Configuration' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'SNM-DRE Queueing Configuration' tab - PASS \n";
    } 

    my $xpath_msuq = "//div[contains (text(), 'MSU Queue Depth')]/following-sibling::div//input[\@value='$MSUQ']";
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $xpath_msuq)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the MSU Queue Depth" );
        print FH "STEP: Verify the MSU Queue Depth - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the MSU Queue Depth - Pass \n";
    }

    my $xpath_time_cong_1 = "//div[contains (text(), 'Time Cong Onset 1')]/following-sibling::div//input[\@value='$TIME_CONG1']";
	unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $xpath_time_cong_1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the Time Cong Onset 1" );
        print FH "STEP: Verify the Time Cong Onset 1 - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the Time Cong Onset 1 - Pass \n";
    }

    my $xpath_time_cong_2 = "//div[contains (text(), 'Time Cong Onset 2')]/following-sibling::div//input[\@value='$TIME_CONG2']";
	unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $xpath_time_cong_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the Time Cong Onset 1" );
        print FH "STEP: Verify the Time Cong Onset 2 - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the Time Cong Onset 2 - Pass \n";
    }

    my $xpath_time_cong_3 = "//div[contains (text(), 'Time Cong Onset 3')]/following-sibling::div//input[\@value='$TIME_CONG3']";
	unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $xpath_time_cong_3)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the Time Cong Onset 1" );
        print FH "STEP: Verify the Time Cong Onset 3 - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the Time Cong Onset 3 - Pass \n";
    }

############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_02 { #Change MTP3 NA Manager 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_02");
    my $sub_name = "ADQ_1411_Auto_MTP3_02";
	my $tcid = "ADQ_1411_Auto_MTP3_02";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	
    my @output_CLI; 
	unless(grep/:VFY-NAMGR:CTAG:COMPLD/, @output_CLI = $ses_CLI1->execCmd("VFY-NAMGR:::[CTAG];")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify NAMGR by command 'VFY-NAMGR:::[CTAG];'  " );
        print FH "STEP: Verify NAMGR by command 'VFY-NAMGR:::[CTAG];'  - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Verify NAMGR by command 'VFY-NAMGR:::[CTAG];'  - PASS \n";  
    }

    my $TL_result;
    foreach (@output_CLI){
        ($TL_result) = $_ =~ /((?<=\t:::).*$)/;
        last if $TL_result;
    }

    my @TL_result_array = split(',',$TL_result);
    my %TL_result_hash;
    foreach (@TL_result_array){
        my @elm = split('=',$_);
        $TL_result_hash{$elm[0]} = $elm[1];
    }
    print Dumper(\%TL_result_hash);  
    my %comparing = {
              'LDL_DBG_LEVEL' => '3',
              'TIME_CONG2' => '900 ms',
              'TELEDIAG' => 'LOGGED',
              'NA_DBG_LEVEL' => '2',
              'TIME_CONG3' => '1200 ms',
              'TIME_CONG1' => '500 ms',
              'MSUQ' => '200000'
            };
    ($TL_result_hash{'TIME_CONG1'}) = $TL_result_hash{'TIME_CONG1'} =~ /(\d+)/;
    ($TL_result_hash{'TIME_CONG2'}) = $TL_result_hash{'TIME_CONG2'} =~ /(\d+)/;
    ($TL_result_hash{'TIME_CONG3'}) = $TL_result_hash{'TIME_CONG3'} =~ /(\d+)/;

    my $init_set = "CHG-NAMGR:::CTAG:::::"
        ."NA_DBG_LEVEL=$TL_result_hash{'NA_DBG_LEVEL'},"
        ."LDL_DBG_LEVEL=$TL_result_hash{'LDL_DBG_LEVEL'},"
        ."TELEDIAG=$TL_result_hash{'TELEDIAG'},"
        ."MSUQ=$TL_result_hash{'MSUQ'},"
        ."TIME_CONG1=$TL_result_hash{'TIME_CONG1'},"
        ."TIME_CONG2=$TL_result_hash{'TIME_CONG2'},"
        ."TIME_CONG3=$TL_result_hash{'TIME_CONG3'};";

    # CHG-NAMGR:::CTAG:::::NA_DBG_LEVEL=2,LDL_DBG_LEVEL=3,TELEDIAG=LOGGED,MSUQ=200000,TIME_CONG1=500,TIME_CONG2=900,TIME_CONG3=1200;
	unless(grep/:CHG-NAMGR:CTAG:COMPLD;/, @output_CLI = $ses_CLI1->execCmd("CHG-NAMGR:::CTAG:::::NA_DBG_LEVEL=2,LDL_DBG_LEVEL=3,TELEDIAG=LOGGED,MSUQ=200000,TIME_CONG1=500,TIME_CONG2=900,TIME_CONG3=1200;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change  MTP3 NA Manager by command 'VFY-NAMGR:::[CTAG];'  " );
        print FH "STEP: Change  MTP3 NA Manager by command 'CHG-NAMGR:::CTAG'  - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change  MTP3 NA Manager by command 'CHG-NAMGR:::CTAG'  - PASS \n";  
    }
	unless(grep/:CHG-NAMGR:CTAG:COMPLD;/, $ses_CLI1->execCmd($init_set)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change  MTP3 NA Manager by command 'VFY-NAMGR:::[CTAG];'  " );
        print FH "STEP: Change  MTP3 NA Manager by command 'CHG-NAMGR:::CTAG'  - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change  MTP3 NA Manager by command 'CHG-NAMGR:::CTAG'  - PASS \n";  
    }    
    foreach (@output_CLI){
        ($TL_result) = $_ =~ /((?<=\t:::).*$)/;
        last if $TL_result;
    }

    @TL_result_array = split(',',$TL_result);
    foreach (@TL_result_array){
        my @elm = split('=',$_);
        $TL_result_hash{$elm[0]} = $elm[1];
    }
    for my $key ( keys %TL_result_hash ) {
        unless($TL_result_hash{$key} ne $comparing{$key}){
            $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify MTP3 NA Manager Result '$key' by command 'VFY-NAMGR:::[CTAG];'  " );
            print FH "STEP: Verify MTP3 NA Manager Result '$key' by command 'CHG-NAMGR:::CTAG'  - FAIL \n";
            $result = 0;
        }else{
            print FH "STEP: Verify MTP3 NA Manager Result '$key' by command 'CHG-NAMGR:::CTAG'  - PASS \n";  
        }   
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_03 { #Set MTP3 NA Manager 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_03");
    my $sub_name = "ADQ_1411_Auto_MTP3_03";
	my $tcid = "ADQ_1411_Auto_MTP3_03";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	
	unless(grep/:CHG-NAMGR:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-NAMGR:::CTAG:::::NA_DBG_LEVEL=2,LDL_DBG_LEVEL=3,TELEDIAG=LOGGED,MSUQ=200000,TIME_CONG1=500,TIME_CONG2=900,TIME_CONG3=1200;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change  MTP3 NA Manager by command 'VFY-NAMGR:::[CTAG];'  " );
        print FH "STEP: Change  MTP3 NA Manager by command 'CHG-NAMGR:::CTAG'  - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change  MTP3 NA Manager by command 'CHG-NAMGR:::CTAG'  - PASS \n";  
    }
    unless(grep/:SET-NAMGR:CTAG:COMPLD;/,$ses_CLI1->execCmd("SET-NAMGR:::CTAG:::RESTORE_DBG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change  MTP3 NA Manager to default by command 'VFY-NAMGR:::[CTAG];'  " );
        print FH "STEP: Change  MTP3 NA Manager to default by command 'CHG-NAMGR:::CTAG'  - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change  MTP3 NA Manager to default by command 'CHG-NAMGR:::CTAG'  - PASS \n";  
    }
    my $vrf_na_dbg_lv = "//div[text()='NA Debug Level']/following-sibling::div//input[\@value='1']";
    my $vrf_ldl_dbg_lv = "//div[text()='LDL Debug Level']/following-sibling::div//input[\@value='2']";
    my $vrf_tel_diag = "//div[text()='Telemetry Diagnostics']/following-sibling::div//option[\@value='LOGGED']";
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    # 
    my $debug_level_cfg = "//a[contains(text(),'Debug Level Configuration')]";
    unless ($ses_Selenium->clickElement(-xPath => $debug_level_cfg)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'Debug Level Configuration' tab" );
        print FH "STEP: Click 'Debug Level Configuration' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'Debug Level Configuration' tab - PASS \n";
    }  
  
	unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_na_dbg_lv)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the Default NA Debug Level" );
        print FH "STEP: Verify the Default NA Debug Level - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the Default NA Debug Level - Pass \n";
    }
	unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_ldl_dbg_lv)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the Default LDL Debug Level" );
        print FH "STEP: Verify the Default LDL Debug Level - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the Default LDL Debug Level - Pass \n";
    }
	unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_tel_diag)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the Telemetry Diagnostics" );
        print FH "STEP: Verify the Default Telemetry Diagnostics - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the Default Telemetry Diagnostics - Pass \n";
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_04 { #Add NA 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_04");
    my $sub_name = "ADQ_1411_Auto_MTP3_04";
	my $tcid = "ADQ_1411_Auto_MTP3_04";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	
    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    # 
    my $vrf_na50_inactive = "//a[contains(text(),'NA 50')]/ancestor::tr//td[text()='INACTIVE']";
	unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_na50_inactive)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the inactive added NA50" );
        print FH "STEP: Verify the inactive added NA50 - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the inactive added NA50 - Pass \n";
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_05 { #Change NA with variant = ANSI 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_05");
    my $sub_name = "ADQ_1411_Auto_MTP3_05";
	my $tcid = "ADQ_1411_Auto_MTP3_05";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    unless(grep/:CHG-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-NA::$NA_50:CTAG:::::LOCAL_PC=50.50.50,SS7_VARIANT=ANSI,PC_DISPLAY=8.8.8,PC_ROUTING=8.8.8,NET_IND=NI_10,CLLI=Autotest;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change NA by command 'CHG-NA::$NA_50:CTAG:::::LOCAL_PC=50.50.50,SS7_VARIANT=ANSI,PC_DISPLAY=8.8.8,PC_ROUTING=8.8.8,NET_IND=NI_10,CLLI=Autotest;'  " );
        print FH "STEP: Change NA by command 'CHG-NA::$NA_50:CTAG:::::LOCAL_PC=50.50.50,SS7_VARIANT=ANSI,PC_DISPLAY=8.8.8,PC_ROUTING=8.8.8,NET_IND=NI_10,CLLI=Autotest;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change NA by command 'CHG-NA::$NA_50:CTAG:::::LOCAL_PC=50.50.50,SS7_VARIANT=ANSI,PC_DISPLAY=8.8.8,PC_ROUTING=8.8.8,NET_IND=NI_10,CLLI=Autotest;' - PASS \n";  
    }
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    # 
    my $vrf_na50_inactive = "//a[contains(text(),'NA 50')]/ancestor::tr//td[text()='INACTIVE']";
	unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_na50_inactive)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the inactive added NA50" );
        print FH "STEP: Verify the inactive added NA50 - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the inactive added NA50 - Pass \n";
    }

    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    my @vrf_;
    my $ind_;
    $vrf_[$ind_++] = "//div[contains(text(),'Context')]/following-sibling::div//span[text()='NA 50 050.050.050']";
    $vrf_[$ind_++] = "//div[contains(text(),'Local Point Code')]/following-sibling::div//input[\@value='050.050.050']";
    $vrf_[$ind_++] = "//div[contains(text(),'SS7 Variant')]/following-sibling::div//option[\@selected='selected' and text()='ANSI']";
    $vrf_[$ind_++] = "//div[contains(text(),'PC Display Format')]/following-sibling::div//input[\@value='8.8.8']";
    $vrf_[$ind_++] = "//div[contains(text(),'PC Routing Format')]/following-sibling::div//input[\@value='8.8.8']";
    $vrf_[$ind_++] = "//div[contains(text(),'Network Indicator')]/following-sibling::div//option[\@selected='selected' and text()='NI_10']";
    $vrf_[$ind_++] = "//div[contains(text(),'Status')]/following-sibling::div//span[text()='INACTIVE']";
    $vrf_[$ind_++] = "//div[contains(text(),'CLLI')]/following-sibling::div//input[\@value='Autotest']";
    $vrf_[$ind_++] = "//div[contains(text(),'Network Appearance')]/following-sibling::div//span[text()='50']";

    foreach (@vrf_){
        my ($desc_) = $_ =~ /((?<=\/\/div\[contains\(text\(\),')[A-Za-z\d\s]*(?='\)]))/;
        unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $_)) {
            $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the $desc_" );
            print FH "STEP: Verify the $desc_ - Fail \n";
            $result = 0;
        } else {
            print FH "STEP: Verify the $desc_ - Pass \n";
        }       
    }
    
    unless(grep/:DLT-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("DLT-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up by command 'DLT-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Clean up NA by command 'DLT-NA::$NA_50:CTAG; - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up NA by command 'DLT-NA::$NA_50:CTAG; - PASS \n";  
    }

############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_06 { #Change NA with variant = ITU 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_06");
    my $sub_name = "ADQ_1411_Auto_MTP3_06";
	my $tcid = "ADQ_1411_Auto_MTP3_06";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    unless(grep/:CHG-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-NA::$NA_50:CTAG:::::LOCAL_PC=3.8.3,SS7_VARIANT=ITU,PC_DISPLAY=3.8.3,PC_ROUTING=3.8.3,NET_IND=NI_00,CLLI=Autotest;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change NA by command 'CHG-NA::$NA_50:CTAG:::::LOCAL_PC=3.8.3,SS7_VARIANT=ITU,PC_DISPLAY=3.8.3,PC_ROUTING=3.8.3,NET_IND=NI_00,CLLI=Autotest;'  " );
        print FH "STEP: Change NA by command 'CHG-NA::$NA_50:CTAG:::::LOCAL_PC=3.8.3,SS7_VARIANT=ITU,PC_DISPLAY=3.8.3,PC_ROUTING=3.8.3,NET_IND=NI_00,CLLI=Autotest;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change NA by command 'CHG-NA::$NA_50:CTAG:::::LOCAL_PC=3.8.3,SS7_VARIANT=ITU,PC_DISPLAY=3.8.3,PC_ROUTING=3.8.3,NET_IND=NI_00,CLLI=Autotest;' - PASS \n";  
    }
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    # 
    my $vrf_na50_inactive = "//a[contains(text(),'NA 50')]/ancestor::tr//td[text()='INACTIVE']";
	unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_na50_inactive)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the inactive added NA50" );
        print FH "STEP: Verify the inactive added NA50 - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the inactive added NA50 - Pass \n";
    }

    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    my @vrf_;
    my $ind_;
    $vrf_[$ind_++] = "//div[contains(text(),'Context')]/following-sibling::div//span[text()='NA 50 3.008.3']";
    $vrf_[$ind_++] = "//div[contains(text(),'Local Point Code')]/following-sibling::div//input[\@value='3.008.3']";
    $vrf_[$ind_++] = "//div[contains(text(),'SS7 Variant')]/following-sibling::div//option[\@selected='selected' and text()='ITU']";
    $vrf_[$ind_++] = "//div[contains(text(),'PC Display Format')]/following-sibling::div//input[\@value='3.8.3']";
    $vrf_[$ind_++] = "//div[contains(text(),'PC Routing Format')]/following-sibling::div//input[\@value='3.8.3']";
    $vrf_[$ind_++] = "//div[contains(text(),'Network Indicator')]/following-sibling::div//option[\@selected='selected' and text()='NI_00']";
    $vrf_[$ind_++] = "//div[contains(text(),'Status')]/following-sibling::div//span[text()='INACTIVE']";
    $vrf_[$ind_++] = "//div[contains(text(),'CLLI')]/following-sibling::div//input[\@value='Autotest']";
    $vrf_[$ind_++] = "//div[contains(text(),'Network Appearance')]/following-sibling::div//span[text()='50']";

    foreach (@vrf_){
        my ($desc_) = $_ =~ /((?<=\/\/div\[contains\(text\(\),')[A-Za-z\d\s]*(?='\)]))/;
        unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $_)) {
            $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the $desc_" );
            print FH "STEP: Verify the $desc_ - Fail \n";
            $result = 0;
        } else {
            print FH "STEP: Verify the $desc_ - Pass \n";
        }       
    }
    
    unless(grep/:DLT-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("DLT-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up by command 'DLT-NA::$NA_50:CTAG;'" );
        print FH "STEP: Clean up NA by command 'DLT-NA::$NA_50:CTAG; - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up NA by command 'DLT-NA::$NA_50:CTAG; - PASS \n";  
    }

############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_07 { #Set NA 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_07");
    my $sub_name = "ADQ_1411_Auto_MTP3_07";
	my $tcid = "ADQ_1411_Auto_MTP3_07";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    unless(grep/:SET-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("SET-NA::$NA_50:CTAG:::ACT;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Enable NA by command 'SET-NA::$NA_50:CTAG:::ACT;'  " );
        print FH "STEP: Enable NA by command 'SET-NA::$NA_50:CTAG:::ACT;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Enable NA by command 'SET-NA::$NA_50:CTAG:::ACT;' - PASS \n";  
    }

    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    # 
    my $vrf_na50_inactive = "//a[contains(text(),'NA 50')]/ancestor::tr//td[text()='ACTIVE']";
	unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_na50_inactive)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the active added NA50" );
        print FH "STEP: Verify the active added NA50 - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the active added NA50 - Pass \n";
    }
    unless(grep/:SET-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("SET-NA::$NA_50:CTAG:::DEACT;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Deactive NA by command 'SET-NA::$NA_50:DEACT;'  " );
        print FH "STEP: Deactive NA by command 'ET-NA::$NA_50:CTAG:::DEACT;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Deactive NA by command 'ET-NA::$NA_50:CTAG:::DEACT;' - PASS \n";  
    }
    unless(grep/:DLT-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("DLT-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up by command 'DLT-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Clean up NA by command 'DLT-NA::$NA_50:CTAG; - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up NA by command 'DLT-NA::$NA_50:CTAG; - PASS \n";  
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_08 { #Verify NA 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_08");
    my $sub_name = "ADQ_1411_Auto_MTP3_08";
	my $tcid = "ADQ_1411_Auto_MTP3_08";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    my @output_CLI; 
	unless(grep/:VFY-NA:CTAG:COMPLD/, @output_CLI = $ses_CLI1->execCmd("VFY-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify NA by command 'VFY-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Verify NA by command 'VFY-NA::$NA_50:CTAG;'  - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Verify NA by command 'VFY-NA::$NA_50:CTAG;'  - PASS \n";  
    }

    my $TL_result;
    foreach (@output_CLI){
        ($TL_result) = $_ =~ /((?<=::$NA_50:)[^:]*$)/;
        last if $TL_result;
    }

    my @expected_array = (
        "CONTEXT",
        "LOCAL_PC",
        "SS7_VARIANT",
        "PC_DISPLAY",
        "PC_ROUTING",
        "NET_IND",
        "STATUS",
        "CLLI",
        "NA",
        "RXMSU",
        "TXMSU",
        "ACTV_SNMSLOT",
        "SLSSIZE",
        "ROTATESLS",
        "SLS_IGNBIT",
        "SLS_LSSELECTBIT",
        "MAX_ECR",
        "GENUPU",
        "LCLMTPRSTSUP",
        "PCNUMVALID",
        "SPARESSFBITS",
        "NI_USER_OVERRIDE",
        "M2PADFTVER",
        "LOADSHARE_MODE",
        "SISLT",
        "SLTMPATTERN",
        "MSUSIZE",
        "LONGMSUINTERVAL",
        "LONGMSUTRAPS",
        "APPIDMGMT",
        "GENERATETFM",
        "DISCMSUDPCOPC",
        "ALARMSACTIVATE",
        "MTP4CXPORT",
        "MATESTP",
        "VNDFEAT",
        "ROUTINGFEAT",
        "R4_8COMPL",
        "CONF_REQUEST",
        "DBGFEAT",
        "DBGERR",
        "DBGSNMMGMT",
        "DBGPEERADM",
        "DBGL2CON",
        "DBGDRECON",
        "DBGDREADM",
        "DBGDRESWTCH",
        "DBGSETUP",
        "DBGOTIMERS",
        "DBGREROUTPROC",
        "DBGCO_CBPROC",
        "DBGLINKSTATUS",
        "DBGL2MSG",
        "DBGUSRMGMT",
        "DBGUSRPRIM",
        "DBGMSU",
        "DBGMSURAW",
        "DBGSLT",
        "DBGSLSTABLES",
        "L3T1",
        "L3T2",
        "L3T3",
        "L3T4",
        "L3T5",
        "L3T6",
        "L3T7",
        "L3T8",
        "L3T10",
        "L3T11",
        "L3T12",
        "L3T13",
        "L3T14",
        "L3T15",
        "L3T16",
        "L3T17",
        "L3T18",
        "L3T19",
        "L3T20",
        "L3T21",
        "L3T22",
        "L3T23",
        "L3T24",
        "L3T25",
        "L3T26",
        "L3T27",
        "L3T28",
        "L3T29",
        "L3T30",
        "L3T31",
        "L3T32",
        "L3T33",
        "L3T34",
        "TXLIST",
        "T19NOTIF",
        "T19LRESET",
        "T19ATTMPTS",
        "T31FLINKCONG",
        "CRDTSUPPORT",
        "CRDTN",
        "CRDTM",
        "CRDTTLOOP",
        "NTTUSNSUPPORT"
    );

    my @TL_result_array = split(',',$TL_result);
    my %TL_result_hash;
    foreach (@TL_result_array){
        my @elm = split('=',$_);
        $TL_result_hash{$elm[0]} = $elm[1];
    }   
        print Dumper(\%TL_result_hash);  
    foreach (@expected_array){
        unless (length($TL_result_hash{$_})){
            $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify NA command 'VFY-NA::50:CTAG;' result fail due to miss '$_'" );
            print FH "STEP: Verify NA command 'VFY-NA::$NA_50:CTAG;' result fail due to miss '$_'  - FAIL \n";
            $result = 0;
        }
    }

    unless(grep/:DLT-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("DLT-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up by command 'DLT-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Clean up NA by command 'DLT-NA::$NA_50:CTAG; - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up NA by command 'DLT-NA::$NA_50:CTAG; - PASS \n";  
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_09 { #Delete NA  
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_09");
    my $sub_name = "ADQ_1411_Auto_MTP3_09";
	my $tcid = "ADQ_1411_Auto_MTP3_09";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    unless(grep/:SET-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("SET-NA::$NA_50:CTAG:::ACT;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Enable NA by command 'SET-NA::$NA_50:CTAG:::ACT;'  " );
        print FH "STEP: Enable NA by command 'SET-NA::$NA_50:CTAG:::ACT;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Enable NA by command 'SET-NA::$NA_50:CTAG:::ACT;' - PASS \n";  
    }

    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    # 
    my $vrf_na50_inactive = "//a[contains(text(),'NA 50')]/ancestor::tr//td[text()='ACTIVE']";
	unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_na50_inactive)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the active added NA50" );
        print FH "STEP: Verify the active added NA50 - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the active added NA50 - Pass \n";
    }
    unless(grep/:SET-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("SET-NA::$NA_50:CTAG:::DEACT;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Deactive NA by command 'SET-NA::$NA_50:DEACT;'  " );
        print FH "STEP: Deactive NA by command 'ET-NA::$NA_50:CTAG:::DEACT;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Deactive NA by command 'ET-NA::$NA_50:CTAG:::DEACT;' - PASS \n";  
    } 
    sleep(5);
    $vrf_na50_inactive = "//a[contains(text(),'NA 50')]/ancestor::tr//td[text()='INACTIVE']";
	unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_na50_inactive)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the INACTIVE NA50" );
        print FH "STEP: Verify the INACTIVE NA50 - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the INACTIVE NA50 - Pass \n";
    }
    
    unless(grep/:DLT-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("DLT-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up by command 'DLT-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Clean up NA by command 'DLT-NA::$NA_50:CTAG; - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up NA by command 'DLT-NA::$NA_50:CTAG; - PASS \n";  
    }
    $vrf_na50_inactive = "//a[contains(text(),'NA 50')]";
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_10 { #Verify DREs 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_10");
    my $sub_name = "ADQ_1411_Auto_MTP3_10";
	my $tcid = "ADQ_1411_Auto_MTP3_10";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	
    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    my @output_cli;
    unless(grep/:VFY-DRES:CTAG:COMPLD/,@output_cli=$ses_CLI1->execCmd("VFY-DRES::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify DRES by command 'VFY-DRES::$NA_50:CTAG;'  " );
        print FH "STEP: Verify DRES by command 'VFY-DRES::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Verify DRES by command 'VFY-DRES::$NA_50:CTAG;' - PASS \n";  
    }

    my $TL_result;
    foreach (@output_cli){
        ($TL_result) = $_ =~ /((?<=::$NA_50:COUNT=)\d+(?=,))/;
        last if length($TL_result);
        
    }
    print("$TL_result \n");
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    my $dres = "//span[contains(text(),'DREs')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $dres)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'DREs'" );
        print FH "STEP: Click the 'DREs' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'DREs' - Pass \n";
    }
    # 
    my $vrf_count_dres = "//div[contains(text(),'Count')]/following-sibling::div/span[text()=$TL_result]";
	unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_count_dres)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the number of DREs equal to '$TL_result'" );
        print FH "STEP: Verify the number of DREs equal to '$TL_result' - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the number of DREs equal to '$TL_result' - Pass \n";
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_11 { #Verify DREs 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_11");
    my $sub_name = "ADQ_1411_Auto_MTP3_11";
	my $tcid = "ADQ_1411_Auto_MTP3_11";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }

    unless(grep/:ADD-DRE:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-DRE::$NA_50-$DRE_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add DRES by command 'ADD-DRE::$NA_50:CTAG;'  " );
        print FH "STEP: Add DRES by command 'ADD-DRE::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add DRES by command 'ADD-DRE::$NA_50:CTAG;' - PASS \n";  
    }

    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    my $dres = "//span[contains(text(),'DREs')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $dres)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'DREs'" );
        print FH "STEP: Click the 'DREs' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'DREs' - Pass \n";
    }
    # 
    my $vrf_count_dres = "//a[contains(text(),'DRE 50')]/ancestor::tr/td[text()='UNAVAILABLE']";
	unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_count_dres)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the UNAVAILABLE DREs" );
        print FH "STEP: Verify the UNAVAILABLE DREs - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the UNAVAILABLE DREs - Pass \n";
    }
    
    unless(grep/:DLT-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("DLT-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up by command 'DLT-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Clean up NA by command 'DLT-NA::$NA_50:CTAG; - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up NA by command 'DLT-NA::$NA_50:CTAG; - PASS \n";  
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_12 { #Verify DREs 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_12");
    my $sub_name = "ADQ_1411_Auto_MTP3_12";
	my $tcid = "ADQ_1411_Auto_MTP3_12";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }

    unless(grep/:ADD-DRE:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-DRE::$NA_50-$DRE_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add DRES by command 'ADD-DRE::$NA_50:CTAG;'  " );
        print FH "STEP: Add DRES by command 'ADD-DRE::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add DRES by command 'ADD-DRE::$NA_50:CTAG;' - PASS \n";  
    }

    unless(grep/:CHG-DRE:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-DRE::50-50:CTAG:::::CLLI=Slot 50,IPADDR1=slot50_0,IPADDR2=;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change DRE by command 'CHG-DRE::50-50:CTAG:::::CLLI=Slot 50,IPADDR1=slot50_0,IPADDR2=;'  " );
        print FH "STEP: Change DRE by command 'CHG-DRE::50-50:CTAG:::::CLLI=Slot 50,IPADDR1=slot50_0,IPADDR2=;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change DRE by command 'CHG-DRE::50-50:CTAG:::::CLLI=Slot 50,IPADDR1=slot50_0,IPADDR2=;' - PASS \n";  
    }

    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    my $dres = "//span[contains(text(),'DREs')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $dres)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'DREs'" );
        print FH "STEP: Click the 'DREs' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'DREs' - Pass \n";
    }
    # 
    my $dres_path = "//a[contains(text(),'DRE 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $dres_path)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'DRE 50'" );
        print FH "STEP: Click the 'DRE 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'DRE 50' - Pass \n";
    }

    my $vrf_clli = "//div[text()='CLLI']/following-sibling::div//input[\@value='Slot 50']";
    my $vrf_ip_addr_1 = "//div[text()='IP Address 1']/following-sibling::div//input[\@value='slot50_0']";
    my $vrf_ip_addr_2 = "//div[text()='IP Address 2']/following-sibling::div//input";
	
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_clli)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the CLLI" );
        print FH "STEP: Verify the CLLI - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the CLLI - Pass \n";
    }    
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_ip_addr_1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the IP Address 1" );
        print FH "STEP: Verify the IP Address 1 - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the IP Address 1 - Pass \n";
    }  
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_ip_addr_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the IP Address 2" );
        print FH "STEP: Verify the IP Address 2 - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the IP Address 2 - Pass \n";
    }  
    
    unless(grep/:DLT-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("DLT-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up by command 'DLT-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Clean up NA by command 'DLT-NA::$NA_50:CTAG; - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up NA by command 'DLT-NA::$NA_50:CTAG; - PASS \n";  
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_13 { #Verify DREs 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_13");
    my $sub_name = "ADQ_1411_Auto_MTP3_13";
	my $tcid = "ADQ_1411_Auto_MTP3_13";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }

    unless(grep/:ADD-DRE:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-DRE::$NA_50-$DRE_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add DRES by command 'ADD-DRE::$NA_50:CTAG;'  " );
        print FH "STEP: Add DRES by command 'ADD-DRE::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add DRES by command 'ADD-DRE::$NA_50:CTAG;' - PASS \n";  
    }
    unless(grep/:CHG-DRE:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-DRE::50-50:CTAG:::::CLLI=Slot 50,IPADDR1=slot50_0,IPADDR2=;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change DRE by command 'CHG-DRE::50-50:CTAG:::::CLLI=Slot 50,IPADDR1=slot50_0,IPADDR2=;'  " );
        print FH "STEP: Change DRE by command 'CHG-DRE::50-50:CTAG:::::CLLI=Slot 50,IPADDR1=slot50_0,IPADDR2=;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change DRE by command 'CHG-DRE::50-50:CTAG:::::CLLI=Slot 50,IPADDR1=slot50_0,IPADDR2=;' - PASS \n";  
    }
    my $vrf_cmd = "::$NA_50-$DRE_50:CONTEXT=/*DRE 50*/,"
                    ."DRE_ID=50,CLLI=/*Slot 50*/,"
                    ."STATE=UNAVAILABLE,"
                    ."IPADDR1=/*slot50_0*/,"
                    ."IPADDR2=/*slot50_1*/,";
    my @output_CLI; 
	unless(grep/:VFY-DRE:CTAG:COMPLD/, @output_CLI = $ses_CLI1->execCmd("VFY-DRE::$NA_50-$DRE_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify DRE by command 'VFY-DRE::$NA_50-$DRE_50:CTAG;'  " );
        print FH "STEP: Verify DRE by command 'VFY-DRE::$NA_50-$DRE_50:CTAG;'  - FAIL \n";
        $result = 0;
        goto CLEANUP; 
    }else{
        print FH "STEP: Verify DRE by command 'VFY-DRE::$NA_50-$DRE_50:CTAG;'  - PASS \n";  
    }

    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    my $dres = "//span[contains(text(),'DREs')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $dres)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'DREs'" );
        print FH "STEP: Click the 'DREs' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'DREs' - Pass \n";
    }
    # 
    my $dres_path = "//a[contains(text(),'DRE 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $dres_path)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'DRE 50'" );
        print FH "STEP: Click the 'DRE 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'DRE 50' - Pass \n";
    }

    my $xpath_dre= " ";


    my $vrf_clli = "//div[text()='CLLI']/following-sibling::div//input[\@value='Slot 50']";
    my $vrf_ip_addr_1 = "//div[text()='IP Address 1']/following-sibling::div//input[\@value='slot50_0']";
    my $vrf_ip_addr_2 = "//div[text()='IP Address 2']/following-sibling::div//input";
	
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_clli)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the CLLI" );
        print FH "STEP: Verify the CLLI - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the CLLI - Pass \n";
    }    
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_ip_addr_1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the IP Address 1" );
        print FH "STEP: Verify the IP Address 1 - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the IP Address 1 - Pass \n";
    }  
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_ip_addr_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the IP Address 2" );
        print FH "STEP: Verify the IP Address 2 - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the IP Address 2 - Pass \n";
    }  
    
    unless(grep/:DLT-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("DLT-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up by command 'DLT-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Clean up NA by command 'DLT-NA::$NA_50:CTAG; - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up NA by command 'DLT-NA::$NA_50:CTAG; - PASS \n";  
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_14 { 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_14");
    my $sub_name = "ADQ_1411_Auto_MTP3_14";
	my $tcid = "ADQ_1411_Auto_MTP3_14";
	my $result= 1;
	my $flag = 1;

    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");

    unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}
    # Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

    unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    #add NA
     unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #add DRE
    unless(grep/:ADD-DRE:CTAG:COMPLD/,$ses_CLI1->execCmd("ADD-DRE::$NA_50-$DRE_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add DRES by command 'ADD-DRE::$NA_50:CTAG;'  " );
        print FH "STEP: Add DRES by command 'ADD-DRE::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add DRES by command 'ADD-DRE::$NA_50:CTAG;' - PASS \n";  
    }
    
    #
    my ($sessionId, $localUrl);
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
    # launch
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA 50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    my $xpath_DREs="//span[contains (text(),'DREs')]";
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_DREs)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #remove DRE 50
    if ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $xpath_DREs, -timeout=>5)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the UNAVAILABLE DREs" );
        print FH "STEP: Verify the UNAVAILABLE DREs - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the UNAVAILABLE DREs - Pass \n";
    }
    #Delete DRE
    unless(grep/:DLT-DRE:CTAG:COMPLD/,$ses_CLI1->execCmd("DLT-DRE::$NA_50-$DRE_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Delete DRE by command 'DLT-DRE::$NA_50-$DRE_50:CTAG;'  " );
        print FH "STEP: Delete DRE by command 'DLT-DRE::$NA_50-$DRE_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Delete DRE by command 'DLT-DRE::$NA_50-$DRE_50:CTAG;' - PASS \n";  
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 

}


sub ADQ_1411_Auto_MTP3_15 { #Verify L2 Connection 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_15");
    my $sub_name = "ADQ_1411_Auto_MTP3_15";
	my $tcid = "ADQ_1411_Auto_MTP3_15";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    my $l2_connections = "//span[text()='L2 Connections']";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $l2_connections)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'L2 Connections'" );
        print FH "STEP: Click the 'L2 Connections' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'L2 Connections' - Pass \n";
    }
    
    unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }

    unless(grep/:ADD-DRE:CTAG:COMPLD/,$ses_CLI1->execCmd("ADD-DRE::$NA_50-$DRE_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add DRES by command 'ADD-DRE::$NA_50:CTAG;'  " );
        print FH "STEP: Add DRES by command 'ADD-DRE::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add DRES by command 'ADD-DRE::$NA_50:CTAG;' - PASS \n";  
    }

    my $vrf_count_dres = "//a[contains(text(),'DRE 50')]/ancestor::tr/td[text()='UNAVAILABLE']";
	unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_count_dres)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the UNAVAILABLE DREs" );
        print FH "STEP: Verify the UNAVAILABLE DREs - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the UNAVAILABLE DREs - Pass \n";
    }

    unless(grep/:DLT-DRE:CTAG:COMPLD/,$ses_CLI1->execCmd("DLT-DRE::$NA_50-$DRE_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Delete DRE by command 'DLT-DRE::$NA_50-$DRE_50:CTAG;'  " );
        print FH "STEP: Delete DRE by command 'DLT-DRE::$NA_50-$DRE_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Delete DRE by command 'DLT-DRE::$NA_50-$DRE_50:CTAG;' - PASS \n";  
    }

    $vrf_count_dres = "//a[contains(text(),'DRE 50')]/ancestor::tr/td[text()='UNAVAILABLE']";
    sleep 5;
	if ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_count_dres, -timeout=>5)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the UNAVAILABLE DREs" );
        print FH "STEP: Verify the UNAVAILABLE DREs - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the UNAVAILABLE DREs - Pass \n";
    }
    unless(grep/:DLT-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("DLT-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up by command 'DLT-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Clean up NA by command 'DLT-NA::$NA_50:CTAG; - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up NA by command 'DLT-NA::$NA_50:CTAG; - PASS \n";  
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_16 { #Add Vnode 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_16");
    my $sub_name = "ADQ_1411_Auto_MTP3_16";
	my $tcid = "ADQ_1411_Auto_MTP3_16";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    unless(grep/:ADD-VND:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-VND::$NA_50-$VNODE:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-VND::$NA_50-$VNODE:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-VND::$NA_50-$VNODE:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-VND::$NA_50-$VNODE:CTAG;' - PASS \n";  
    }
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    my $vnode = "//span[contains(text(),'VNodes')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $vnode)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'VNODEs'" );
        print FH "STEP: Click the 'VNODEs' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'VNODEs' - Pass \n";
    }
    # # 
    my $vrf_vnode = "//a[contains(text(),'VNODE 001.001.001')]/ancestor::tr//td[text()='ACTIVE']";
	unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_vnode)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the added VNODE" );
        print FH "STEP: Verify the added VNODE - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the added VNODE - Pass \n";
    }  
    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up MTP3" );
        print FH "STEP: Clean up MTP3 - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up MTP3 - PASS \n";  
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_17 { #Change Vnode
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_17");
    my $sub_name = "ADQ_1411_Auto_MTP3_17";
	my $tcid = "ADQ_1411_Auto_MTP3_17";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	
    #--cleanup before testing
    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    #--add NA
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #--add VNode
    unless(grep/:ADD-VND:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-VND::$NA_50-$VNODE:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-VND::$NA_50-$VNODE:CTAG;'  " );
        print FH "STEP: Add VNode by command 'ADD-VND::$NA_50-$VNODE:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add VNode by command 'ADD-VND::$NA_50-$VNODE:CTAG;' - PASS \n";  
    }
    #--change VNode
    unless(grep/:CHG-VND:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-VND::50-1.1.1:CTAG:::::CLLI=Vnode1,DESC=Autotest,TFA=DISABLED,TFP=DISABLED,TFR=DISABLED;")){
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change VNode by command 'CHG-VND::50-1.1.1:CTAG:::::CLLI=Vnode1,DESC=Autotest,TFA=DISABLED,TFP=DISABLED,TFR=DISABLED;");
        print FH "STEP: Change VNode by command 'CHG-VND::50-1.1.1:CTAG:::::CLLI=Vnode1,DESC=Autotest,TFA=DISABLED,TFP=DISABLED,TFR=DISABLED;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change VNode by command 'CHG-VND::50-1.1.1:CTAG:::::CLLI=Vnode1,DESC=Autotest,TFA=DISABLED,TFP=DISABLED,TFR=DISABLED;' - PASS \n";  
    }

    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)){
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    my $vnode = "//span[contains(text(),'VNodes')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $vnode)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Vnode'" );
        print FH "STEP: Click the 'Vnode' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Vnode' - Pass \n";
    }
    # 
    my $xpath_vnode_001 = "//a[contains(text(),'VNODE 001.001.001')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_vnode_001)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'VNODE 001.001.001'" );
        print FH "STEP: Click the 'VNODE 001.001.001' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'VNODE 001.001.001' - Pass \n";
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_18 { #Set VNode 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_18");
    my $sub_name = "ADQ_1411_Auto_MTP3_18";
	my $tcid = "ADQ_1411_Auto_MTP3_18";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	
    #cleanup before testing
    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    unless(grep/:ADD-VND:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-VND::$NA_50-$VNODE:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add Vnode by command 'ADD-VND::$NA_50-$VNODE:CTAG;'  " );
        print FH "STEP: Add Vnode by command 'ADD-VND::$NA_50-$VNODE:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add Vnode by command 'ADD-VND::$NA_50-$VNODE:CTAG;' - PASS \n";  
    }

    unless(grep/:SET-VND:CTAG:COMPLD;/,$ses_CLI1->execCmd("SET-VND::50-1.1.1:CTAG:::DEACT;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Enable VNode by command 'SET-VND::50-1.1.1:CTAG:::DEACT;'  " );
        print FH "STEP: Enable VNode by command 'SET-VND::50-1.1.1:CTAG:::DEACT;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Enable VNode by command 'SET-VND::50-1.1.1:CTAG:::DEACT;' - PASS \n";  
    }

    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    # click NA
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #--click VNode tab
    my $vnode = "//span[contains(text(),'VNodes')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $vnode)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'VNODEs'" );
        print FH "STEP: Click the 'VNODEs' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'VNODEs' - Pass \n";
    }
    #---click VNODE 001.001.001
    my $xpath_vnode_001 = "//a[contains(text(),'VNODE 001.001.001')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_vnode_001)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'VNODE 001.001.001'" );
        print FH "STEP: Click the 'VNODE 001.001.001' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'VNODE 001.001.001' - Pass \n";
    }
    #---click Deactivate
    my $vrf_deactivate = "//input[\@value='Deactivate'][2]";
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_deactivate)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the Deactivate" );
        print FH "STEP: Verify the Deactivate - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the Deactivate - Pass \n";
    }    
    #--click button Continue
    my $xpath_continue="//input[\@value='Continue']";
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $xpath_continue)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the button Continue" );
        print FH "STEP: Verify the button Continue - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the button Continue - Pass \n";
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_19 { #Verify VNode 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_19");
    my $sub_name = "ADQ_1411_Auto_MTP3_19";
	my $tcid = "ADQ_1411_Auto_MTP3_19";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	
    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    unless(grep/:ADD-VND:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-VND::$NA_50-$VNODE:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add VNode by command 'ADD-VND::$NA_50-$VNODE:CTAG;'  " );
        print FH "STEP: Add VNode by command 'ADD-VND::$NA_50-$VNODE:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add VNode by command 'ADD-VND::$NA_50-$VNODE:CTAG;' - PASS \n";  
    }
    unless(grep/:CHG-VND:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-VND::50-1.1.1:CTAG:::::CLLI=Vnode1,DESC=Autotest,TFA=DISABLED,TFP=DISABLED,TFR=DISABLED;")){
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change VNode by command 'CHG-VND::50-1.1.1:CTAG:::::CLLI=Vnode1,DESC=Autotest,TFA=DISABLED,TFP=DISABLED,TFR=DISABLED;");
        print FH "STEP: Change VNode by command 'CHG-VND::50-1.1.1:CTAG:::::CLLI=Vnode1,DESC=Autotest,TFA=DISABLED,TFP=DISABLED,TFR=DISABLED;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change VNode by command 'CHG-VND::50-1.1.1:CTAG:::::CLLI=Vnode1,DESC=Autotest,TFA=DISABLED,TFP=DISABLED,TFR=DISABLED;' - PASS \n";  
    }

    #VERIFY VNODE
    unless(grep/:VFY-VND:CTAG:COMPLD/,$ses_CLI1->execCmd("VFY-VND::50-1.1.1:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify VNode by command 'VFY-VND::50-1.1.1:CTAG;'  " );
        print FH "STEP: Verify VNode by command 'VFY-VND::50-1.1.1:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Verify VNode by command 'VFY-VND::50-1.1.1:CTAG;' - PASS \n";  
    }
    my ($sessionId, $localUrl);

	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    # click NA
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #--click VNode tab
    my $vnode = "//span[contains(text(),'VNodes')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $vnode)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'VNODEs'" );
        print FH "STEP: Click the 'VNODEs' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'VNODEs' - Pass \n";
    }
    #---click VNODE 001.001.001
    my $xpath_vnode_001 = "//a[contains(text(),'VNODE 001.001.001')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_vnode_001)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'VNODE 001.001.001'" );
        print FH "STEP: Click the 'VNODE 001.001.001' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'VNODE 001.001.001' - Pass \n";
    }

    my $vrf_clli = "//div[text()='CLLI']/following-sibling::div//input";
    my $vrf_description = "//div[text()='Description']/following-sibling::div//input";
    my $vrf_TFA = "//div[text()='Broadcast TFA']/ancestor::div[1]//option[\@value='DISABLED']";
    my $vrf_TFP = "//div[text()='Broadcast TFP']/ancestor::div[1]//option[\@value='DISABLED']";
    my $vrf_TFR = "//div[text()='Broadcast TFR']/ancestor::div[1]//option[\@value='DISABLED']";
	
    unless (grep/Vnode1/,$ses_Selenium->getAttribute( -xPath => $vrf_clli, -attribute => 'value')) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the CLLI" );
        print FH "STEP: Verify the CLLI - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the CLLI - Pass \n";
    }    

    unless (grep/Autotest/,$ses_Selenium->getAttribute(-xPath => $vrf_description,-attribute => 'value')) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the description" );
        print FH "STEP: Verify the description - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the description - Pass \n";
    }  
    unless (grep/DISABLE/,$ses_Selenium->getText( -xPath => $vrf_TFA)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the TFA" );
        print FH "STEP: Verify the TFA - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the TFA - Pass \n";
    }  
    unless (grep/DISABLE/,$ses_Selenium->getText( -xPath => $vrf_TFP)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the TFP" );
        print FH "STEP: Verify the TFP - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the TFP - Pass \n";
    }  
    unless (grep/DISABLE/,$ses_Selenium->getText( -xPath => $vrf_TFR)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the TFR" );
        print FH "STEP: Verify the TFR - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the TFR - Pass \n";
    }  
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}


sub ADQ_1411_Auto_MTP3_20 { 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_20");
    my $sub_name = "ADQ_1411_Auto_MTP3_20";
	my $tcid = "ADQ_1411_Auto_MTP3_20";
	my $result= 1;
	my $flag = 1;

    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");

    unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}
    # Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

    unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	
    #cleanup before testing
    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    #add NA
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #add Vnode
    unless(grep/:ADD-VND:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-VND::50-1.1.1:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add VNode by command 'ADD-VND::50-1.1.1:CTAG;'  " );
        print FH "STEP: Add VNode by command 'ADD-VND::50-1.1.1:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add VNode by command 'ADD-VND::50-1.1.1:CTAG;' - PASS \n";  
    }
    #set Vnode
    #check INACTIVATE, ACTIVATE
    unless(grep/(already inactive|:"Invalid AID";|:SET-VND:CTAG:COMPLD;)/,$ses_CLI1->execCmd("SET-VND::50-1.1.1:CTAG:::DEACT;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to DEACT DRE by command SET-VND::50-1.1.1:CTAG:::DEACT;'  " );
        print FH "STEP: DEACT VNode by command 'SET-VND::50-1.1.1:CTAG:::DEACT;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: DEACT VNode by command 'SET-VND::50-1.1.1:CTAG:::DEACT;' - PASS \n";  
    }
    my ($sessionId, $localUrl);
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
    # launch
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA 50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #click Vnode tab
    my $vnode = "//span[contains(text(),'VNodes')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $vnode)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'VNODEs'" );
        print FH "STEP: Click the 'VNODEs' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'VNODEs' - Pass \n";
    }
    #delete  Vnode
    unless(grep/:DLT-VND:CTAG:COMPLD;/,$ses_CLI1->execCmd("DLT-VND::50-1.1.1:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Delete DRE by command 'DLT-VND::50-1.1.1:CTAG;'  " );
        print FH "STEP: Delete VNode by command 'DLT-VND::50-1.1.1:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Delete VNode by command 'DLT-VND::50-1.1.1:CTAG;' - PASS \n";  
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}



sub ADQ_1411_Auto_MTP3_21 { #Add Routeset 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_21");
    my $sub_name = "ADQ_1411_Auto_MTP3_21";
	my $tcid = "ADQ_1411_Auto_MTP3_21";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Routeset
    unless(grep/:ADD-RTESET:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;'  " );
        print FH "STEP: Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;' - PASS \n";  
    }
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    
    #click Routesets
    my $xpath_routesets = "//span[contains(text(),'Routesets')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_routesets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Routesets'" );
        print FH "STEP: Click the 'Routesets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Routesets' - Pass \n";
    } 
    #---click MRS 0:051.051.051
    my $xpath_routeset = "//a[contains (text(), 'MRS 0:051.051.051')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_routeset)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' MRS 0:051.051.051'" );
        print FH "STEP: Click the ' MRS 0:051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' MRS 0:051.051.051' - Pass \n";
    }
    #---click Deactivate
    my $vrf_deactivate = "//input[\@value='Deactivate'][2]";
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_deactivate)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the Deactivate" );
        print FH "STEP: Verify the Deactivate - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the Deactivate - Pass \n";
    }    
    #--click button Continue
    my $xpath_continue="//input[\@value='Continue']";
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $xpath_continue)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the button Continue" );
        print FH "STEP: Verify the button Continue - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the button Continue - Pass \n";
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_22 { #Change Routeset 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_22");
    my $sub_name = "ADQ_1411_Auto_MTP3_22";
	my $tcid = "ADQ_1411_Auto_MTP3_22";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Routeset
    unless(grep/:ADD-RTESET:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;'  " );
        print FH "STEP: Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;' - PASS \n";  
    }
    #change Routeset
    unless(grep/:CHG-RTESET:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG:::::CLLI=Autotest_RS1;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to change ROUTER by command 'CHG-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG:::::CLLI=Autotest_RS1;'  " );
        print FH "STEP: Change ROUTER by command 'CHG-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG:::::CLLI=Autotest_RS1;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change ROUTER by command 'CHG-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG:::::CLLI=Autotest_RS1;' - PASS \n";  
    }
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    my $na50 = "//a[contains(text(),'NA 50')]";
    my $vnode = "//span[contains(text(),'Routesets')]";
    my $xpath_routeset = "//a[contains (text(), 'MRS 0:051.051.051')]";
    my $xpath_routeset_state = "//div[contains (text(), 'Routeset State')]/ancestor::div//span[text() = 'ACTIVE'] ";
    my $xpath_clli = "//div[text() = 'CLLI']/ancestor::div//input[\@value='Autotest_RS1']";
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    
    #click Routesets
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $vnode)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Routesets'" );
        print FH "STEP: Click the 'Routesets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Routesets' - Pass \n";
    } 
    #---click MRS 0:051.051.051
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_routeset)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' MRS 0:051.051.051'" );
        print FH "STEP: Click the ' MRS 0:051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' MRS 0:051.051.051' - Pass \n";
    }

    #verify routeset
    unless (grep/Autotest_RS1/,$ses_Selenium->getAttribute( -xPath => $xpath_clli, -attribute => 'value')) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the CLLI" );
        print FH "STEP: Verify the CLLI - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the CLLI - Pass \n";
    }  
    
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}


sub ADQ_1411_Auto_MTP3_23 { #Add Linkset 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_23");
    my $sub_name = "ADQ_1411_Auto_MTP3_23";
	my $tcid = "ADQ_1411_Auto_MTP3_23";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }

    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #---click Linksets
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets'" );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}


sub ADQ_1411_Auto_MTP3_24 { #Change Linkset 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_24");
    my $sub_name = "ADQ_1411_Auto_MTP3_24";
	my $tcid = "ADQ_1411_Auto_MTP3_24";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #change Linkset
    unless(grep/:CHG-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-LS::50-51.51.51:CTAG:::::CLLI=to51;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'CHG-LS::50-51.51.51:CTAG:::::CLLI=to51;'  " );
        print FH "STEP: Change LINKSET by command 'CHG-LS::50-51.51.51:CTAG:::::CLLI=to51;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change LINKSET by command CHG-LS::50-51.51.51:CTAG:::::CLLI=to51;' - PASS \n";  
    }
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #---click Linksets
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
    my $xpath_ls = "//a[text() = 'LS 051.051.051']";
    my $verify_linksets = "//div[text() = 'CLLI' ]/ancestor::div//input[\@value = 'to51']";

	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets'" );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }
    
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets'" );
        print FH "STEP: Click the ' Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets 051.051.051' - Pass \n";
    }
    
    #---VERIFY CLLI Linksets
    unless (grep/to51/,$ses_Selenium->getAttribute( -xPath => $verify_linksets, -attribute => 'value')) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the CLLI" );
        print FH "STEP: Verify the CLLI - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the CLLI - Pass \n";
    } 
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_25 { #Add Add M2PA link 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_25");
    my $sub_name = "ADQ_1411_Auto_MTP3_25";
	my $tcid = "ADQ_1411_Auto_MTP3_25";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add M2PA link by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add M2PA link by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add M2PA link by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Add M2PA Link
    unless(grep/:ADD-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-SLK::50-51.51.51-0:CTAG::::M2PA:DRE_ID=1;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add M2PA link by command 'ADD-SLK::50-51.51.51-0:CTAG::::M2PA:DRE_ID=1;'" );
        print FH "STEP: Add M2PA link by command 'ADD-SLK::50-51.51.51-0:CTAG::::M2PA:DRE_ID=1;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add M2PA link by command 'ADD-SLK::50-51.51.51-0:CTAG::::M2PA:DRE_ID=1;' - PASS \n";  
    }

    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    
    #---click Linksets
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
    my $xpath_ls_2 = "//a[text() = 'LS 051.051.051' ]";
    my $xpath_m2pa_link = "//a[text()='051.051.051-00']";


	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets'" );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }
    #click LS 051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Linksets 051.051.051'" );
        print FH "STEP: Click the ' Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets 051.051.051' - Pass \n";
    }
    #click M2PA Link
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_m2pa_link)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'M2PA Link Selection'" );
        print FH "STEP: Click the 'M2PA Link Selection' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'M2PA Link Selection' - Pass \n";
    }
    
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_26 { #Change M2PA link 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_26");
    my $sub_name = "ADQ_1411_Auto_MTP3_26";
	my $tcid = "ADQ_1411_Auto_MTP3_26";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add M2PA link by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add M2PA link by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add M2PA link by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Add M2PA Link
    unless(grep/:ADD-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-SLK::50-51.51.51-0:CTAG::::M2PA:DRE_ID=1;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add M2PA link by command 'ADD-SLK::50-51.51.51-0:CTAG::::M2PA:DRE_ID=1;'" );
        print FH "STEP: Add M2PA link by command 'ADD-SLK::50-51.51.51-0:CTAG::::M2PA:DRE_ID=1;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add M2PA link by command 'ADD-SLK::50-51.51.51-0:CTAG::::M2PA:DRE_ID=1;' - PASS \n";  
    }
    #change M2PA Link
    unless(grep/:CHG-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-SLK::50-51.51.51-0:CTAG::::M2PA:LOCAL_IPADDR1=slot3_0,LOCAL_PORT=1234,REMOTE_IPADDR1=slot3_0,REMOTE_PORT=1235;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change M2PA link by command 'CHG-SLK::50-51.51.51-0:CTAG::::M2PA:LOCAL_IPADDR1=slot3_0,LOCAL_PORT=1234,REMOTE_IPADDR1=slot3_0,REMOTE_PORT=1235;'  " );
        print FH "STEP: Change M2PA link by command 'CHG-SLK::50-51.51.51-0:CTAG::::M2PA:LOCAL_IPADDR1=slot3_0,LOCAL_PORT=1234,REMOTE_IPADDR1=slot3_0,REMOTE_PORT=1235;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change M2PA link by command 'CHG-SLK::50-51.51.51-0:CTAG::::M2PA:LOCAL_IPADDR1=slot3_0,LOCAL_PORT=1234,REMOTE_IPADDR1=slot3_0,REMOTE_PORT=1235;' - PASS \n";  
    }

    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    
    my $link_selection_m2pa = "//a[text() ='051.051.051-15']";
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
    my $xpath_ls = "//a[text() = 'LS 051.051.051' ]";
    my $xpath_m2pa_link = "//a[text()='051.051.051-00']";
    #---click Linksets
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets'" );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }
    #click LS 051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets 051.051.051'" );
        print FH "STEP: Click the ' Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets 051.051.051' - Pass \n";
    }
    #click M2PA Link
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_m2pa_link)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'M2PA Link Selection'" );
        print FH "STEP: Click the 'M2PA Link Selection' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'M2PA Link Selection' - Pass \n";
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}


sub ADQ_1411_Auto_MTP3_27 { #Set M2PA link 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_27");
    my $sub_name = "ADQ_1411_Auto_MTP3_27";
	my $tcid = "ADQ_1411_Auto_MTP3_27";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    #add NA
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #set NA
    unless(grep/:SET-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("SET-NA::50:CTAG:::ACT;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Enable NA by command 'SET-NA::50:CTAG:::ACT;'  " );
        print FH "STEP: Enable NA by command 'SET-NA::50:CTAG:::ACT;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Enable NA by command 'SET-NA::50:CTAG:::ACT;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add M2PA link by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add M2PA link by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add M2PA link by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Add M2PA Link
    unless(grep/:ADD-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-SLK::50-51.51.51-0:CTAG::::M2PA:DRE_ID=1;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add M2PA link by command 'ADD-SLK::50-51.51.51-0:CTAG::::M2PA:DRE_ID=1;'" );
        print FH "STEP: Add M2PA link by command 'ADD-SLK::50-51.51.51-0:CTAG::::M2PA:DRE_ID=1;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add M2PA link by command 'ADD-SLK::50-51.51.51-0:CTAG::::M2PA:DRE_ID=1;' - PASS \n";  
    }
    #Set M2PA link
    unless(grep/:SET-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("SET-SLK::50-51.51.51-0:CTAG:::ACT:M2PA;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add M2PA link by command ' SET-SLK::50-51.51.51-0:CTAG:::ACT:M2PA;'" );
        print FH "STEP: Set M2PA link by command 'SET-SLK::50-51.51.51-0:CTAG:::ACT:M2PA;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Set M2PA link by command 'SET-SLK::50-51.51.51-0:CTAG:::ACT:M2PA;' - PASS \n";  
    }
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";  
    my $na50 = "//a[contains(text(),'NA 50')]";  
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
    my $xpath_ls = "//a[text() = 'LS 051.051.051' ]";
    my $xpath_m2pa_link = "//a[text() ='051.051.051-00']";
    my $vrf_l2_state = "//div[text()='L2 State']/ancestor::div//span[text()='NOT_INITIALIZED']";
    my $vrf_l3_state = "//div[text()='L3 State']/ancestor::div//span[text()='OUT_OF_SERVICE']";
    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #---click Linksets
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Linksets'" );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }
    #click LS 051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Linksets 051.051.051'" );
        print FH "STEP: Click the ' Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets 051.051.051' - Pass \n";
    }
    #click M2PA link
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_m2pa_link)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'M2PA Link Selection' " );
        print FH "STEP: Click 'M2PA Link Selection' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'M2PA Link Selection'  - PASS \n";
    }  
   
    #M2PA link changed: L2 State = NOT_INITIALIZED 
    unless (grep/NOT_INITIALIZED/,$ses_Selenium->getText( -xPath => $vrf_l2_state)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the L2 State" );
        print FH "STEP: Verify the L2 State - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the L2 State - Pass \n";
    }  
    unless (grep/OUT_OF_SERVICE/,$ses_Selenium->getText( -xPath => $vrf_l3_state)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the L3 State" );
        print FH "STEP: Verify the L3 State - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the L3 State - Pass \n";
    }  

    unless(grep/:SET-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("SET-SLK::50-51.51.51-0:CTAG:::DEACT:M2PA;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add M2PA link by command ' SET-SLK::50-51.51.51-0:CTAG:::DEACT:M2PA;'  " );
        print FH "STEP: Set M2PA link by command ' SET-SLK::50-51.51.51-0:CTAG:::DEACT:M2PA;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Set M2PA link by command ' SET-SLK::50-51.51.51-0:CTAG:::DEACT:M2PA;' - PASS \n";  
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}


sub ADQ_1411_Auto_MTP3_28 { #Verify M2PA link 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_28");
    my $sub_name = "ADQ_1411_Auto_MTP3_28";
	my $tcid = "ADQ_1411_Auto_MTP3_28";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    #add NA
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add M2PA link by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add M2PA link by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add M2PA link by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Add M2PA Link
    unless(grep/:ADD-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-SLK::50-51.51.51-0:CTAG::::M2PA:DRE_ID=1;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add M2PA link by command 'ADD-SLK::50-51.51.51-0:CTAG::::M2PA:DRE_ID=1;'" );
        print FH "STEP: Add M2PA link by command 'ADD-SLK::50-51.51.51-0:CTAG::::M2PA:DRE_ID=1;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add M2PA link by command 'ADD-SLK::50-51.51.51-0:CTAG::::M2PA:DRE_ID=1;' - PASS \n";  
    }
    #change M2PA Link
    unless(grep/:CHG-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-SLK::50-51.51.51-0:CTAG::::M2PA:LOCAL_IPADDR1=slot3_0,LOCAL_PORT=1234,REMOTE_IPADDR1=slot3_0,REMOTE_PORT=1235;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change M2PA link by command 'CHG-SLK::50-51.51.51-0:CTAG::::M2PA:LOCAL_IPADDR1=slot3_0,LOCAL_PORT=1234,REMOTE_IPADDR1=slot3_0,REMOTE_PORT=1235;'  " );
        print FH "STEP: Change M2PA link by command 'CHG-SLK::50-51.51.51-0:CTAG::::M2PA:LOCAL_IPADDR1=slot3_0,LOCAL_PORT=1234,REMOTE_IPADDR1=slot3_0,REMOTE_PORT=1235;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change M2PA link by command 'CHG-SLK::50-51.51.51-0:CTAG::::M2PA:LOCAL_IPADDR1=slot3_0,LOCAL_PORT=1234,REMOTE_IPADDR1=slot3_0,REMOTE_PORT=1235;' - PASS \n";  
    }
    #Verify M2PA link
    unless(grep/:VFY-SLK-M2PA:CTAG:COMPLD/,$ses_CLI1->execCmd("VFY-SLK-M2PA::50-51.51.51-0:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify M2PA link by command 'VFY-SLK-M2PA::50-51.51.51-0:CTAG;'  " );
        print FH "STEP: Verify M2PA link by command 'VFY-SLK-M2PA::50-51.51.51-0:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Verify M2PA link by command 'VFY-SLK-M2PA::50-51.51.51-0:CTAG;' - PASS \n";  
    }
    
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]"; 
    my $na50 = "//a[contains(text(),'NA 50')]";
    my $m2pa_link_selection = "//a[contains (text(),'051.051.051-00')]";
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
    my $xpath_ls = "//a[text() = 'LS 051.051.051' ]";
    #verify
    my (@vrf_m2pa_ , $ind_);
    $vrf_m2pa_[$ind_++] = "//div[text()='Context']/ancestor::div[1]//span[text()='051.051.051-00']";
    $vrf_m2pa_[$ind_++] = "//div[contains(text(),'APC')]/ancestor::div[1]//span[text()='051.051.051']";
    $vrf_m2pa_[$ind_++] = "//div[contains(text(),'Link Name')]/ancestor::div[1]//span[text()='051.051.051-00']";
    $vrf_m2pa_[$ind_++] = "//div[contains(text(),'SLC')]/ancestor::div[1]//span[text()='0']";
    $vrf_m2pa_[$ind_++] = "//div[contains(text(),'DRE ID')]/ancestor::div[1]//span[text()='1']";
    $vrf_m2pa_[$ind_++] = "//div[contains(text(),'Local IP Address 1')]/ancestor::div[1]//input[\@value='slot3_0']";
    $vrf_m2pa_[$ind_++] = "//div[contains(text(),'Local IP Address 2')]/parent::div//input";
    $vrf_m2pa_[$ind_++] = "//div[contains(text(),'Local Port')]/ancestor::div//input[\@value='1234']";
    $vrf_m2pa_[$ind_++] = "//div[contains(text(),'Remote IP Address 1')]/ancestor::div[1]//input[\@value='slot3_0']";
    $vrf_m2pa_[$ind_++] = "//div[contains(text(),'Remote IP Address 2')]/ancestor::div[1]//input";
    $vrf_m2pa_[$ind_++] = "//div[contains(text(),'Remote Port')]/ancestor::div//input[\@value='1235']";
    $vrf_m2pa_[$ind_++] = "//div[contains(text(),'L2 State')]/ancestor::div//span[text()='NOT_INITIALIZED']";
    $vrf_m2pa_[$ind_++] = "//div[contains(text(),'L3 State')]/ancestor::div//span[text()='DEACTIVATED']";
    $vrf_m2pa_[$ind_++] = "//div[contains(text(),'Congestion Level')]/ancestor::div//span[text()='FALSE']";
    $vrf_m2pa_[$ind_++] = "//div[contains(text(),'Rx MSU Count')]/ancestor::div[1]//span[text()='0']";
    $vrf_m2pa_[$ind_++] = "//div[contains(text(),'Tx MSU Count')]/ancestor::div[1]//span[text()='0']";
    $vrf_m2pa_[$ind_++] = "//div[contains(text(),'Diagnostic Message')]/ancestor::div//span[text()='Configured']";
    $vrf_m2pa_[$ind_++] = "//div[contains(text(),'DataLink Bandwidth')]/ancestor::div//input[\@value='64']";
    $vrf_m2pa_[$ind_++] = "//div[contains(text(),'M2PA Version')]/ancestor::div//option[\@value='RFC 4165']";
    $vrf_m2pa_[$ind_++] = "//div[contains(text(),'Alarms')]/ancestor::div[1]//option[\@value='ENABLED']";
    $vrf_m2pa_[$ind_++] = "//div[contains(text(),'User Activated')]/ancestor::div//span[text() ='DISABLED']";
    $vrf_m2pa_[$ind_++] = "//div[contains(text(),'GR310 Virtual Link')]/ancestor::div[1]//option[\@value ='DISABLED']";
   
    my (@vrf_deg_config_, $deg_);
    my $deg_config ="//a[contains (text(), 'Debug Configuration')]";
    $vrf_deg_config_[$deg_++] = "//div[contains(text(),'Data Debug Level')]/ancestor::div[1]//input[\@value='1']";
    $vrf_deg_config_[$deg_++] = "//div[contains(text(),'Protocol Debug Level')]/ancestor::div[1]//input[\@value='10']";
    $vrf_deg_config_[$deg_++] = "//div[contains(text(),'Software Debug Level')]/ancestor::div[1]//input[\@value='1']";
    
    my (@vrf_cong_conf_, $ind);
    my $cong_conf = "//a [contains (text(), 'Congestion Configuration')]";
    $vrf_cong_conf_[$ind++] = "//div[contains(text(),'TX Abatement L1')]/ancestor::div//input[\@value='30 %']";
    $vrf_cong_conf_[$ind++] = "//div[contains(text(),'TX Onset L1')]/ancestor::div//input[\@value='40 %']";
    $vrf_cong_conf_[$ind++] = "//div[contains(text(),'TX Abatement L2')]/ancestor::div//input[\@value='50 %']";
    $vrf_cong_conf_[$ind++] = "//div[contains(text(),'TX Onset L2')]/ancestor::div//input[\@value='60 %']";
    $vrf_cong_conf_[$ind++] = "//div[contains(text(),'TX Abatement L3')]/ancestor::div//input[\@value='70 %']";
    $vrf_cong_conf_[$ind++] = "//div[contains(text(),'TX Onset L3')]/ancestor::div//input[\@value='80 %']";
    $vrf_cong_conf_[$ind++] = "//div[contains(text(),'RX Abatement Busy')]/ancestor::div//input[\@value='9900000']";
    $vrf_cong_conf_[$ind++] = "//div[contains(text(),'RX Onset Busy')]/ancestor::div//input[\@value='10000000']";
    $vrf_cong_conf_[$ind++] = "//div[contains(text(),'TX Queue Size')]/ancestor::div//input[\@value='3000000']";
    
    my (@vrf_sctp_conf_, $ind__);
    my $sctp_conf = "//a[contains (text(), 'SCTP Configuration')]";
    $vrf_sctp_conf_[$ind__++] = "//div[contains(text(),'Linkset SCTP Values')]/ancestor::div//option[\@value='YES']";
    $vrf_sctp_conf_[$ind__++] = "//div[contains(text(),'Heartbeat')]/ancestor::div[1]//option[\@value='ENABLED']";
    $vrf_sctp_conf_[$ind__++] = "//div[contains(text(),'Heartbeat Interval')]/ancestor::div//input[\@value='150']";
    $vrf_sctp_conf_[$ind__++] = "//div[contains(text(),'RTO Initial')]/ancestor::div[1]//input[\@value='180']";
    $vrf_sctp_conf_[$ind__++] = "//div[contains(text(),'RTO Minimum')]/ancestor::div[1]//input[\@value='180']";
    $vrf_sctp_conf_[$ind__++] = "//div[contains(text(),'RTO Maximum')]/ancestor::div//input[\@value='250']";
    $vrf_sctp_conf_[$ind__++] = "//div[contains(text(),'Maximum Path Retrans')]/ancestor::div//input[\@value='10']";
    $vrf_sctp_conf_[$ind__++] = "//div[contains(text(),'Maximum Assoc Retrans')]/ancestor::div//input[\@value='15']";
    $vrf_sctp_conf_[$ind__++] = "//div[contains(text(),'Bundling')]/ancestor::div[1]//option[\@value='ENABLED']";
    $vrf_sctp_conf_[$ind__++] = "//div[contains(text(),'Bundling TO')]/ancestor::div[1]//input[\@value='20']";
    $vrf_sctp_conf_[$ind__++] = "//div[contains(text(),'Delayed ACK TO')]/ancestor::div[1]//input[\@value='20']";
    $vrf_sctp_conf_[$ind__++] = "//div[contains(text(),'Fast Retrans Threshold')]/ancestor::div[1]//input[\@value='4']";
    $vrf_sctp_conf_[$ind__++] = "//div[contains(text(),'Checksum')]/ancestor::div//span[text()='CRC32C']";
    $vrf_sctp_conf_[$ind__++] = "//div[contains(text(),'Send INIT')]/ancestor::div[1]//option[text()='ENABLED']";
    
    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #---click Linksets
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets'" );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }
    #click LS 051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets 051.051.051'" );
        print FH "STEP: Click the ' Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets 051.051.051' - Pass \n";
    }

    #click M2PA Link Configuration
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $m2pa_link_selection)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'M2PA Link Selection' " );
        print FH "STEP: Click 'M2PA Link Selection' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'M2PA Link Selection'  - PASS \n";
    }  
    #verify M2PA Link Configuration
    foreach(@vrf_m2pa_){
        my ($ind_) = $_ =~ /((?<=\/\/div\[contains\(text\(\),')[A-Za-z\d\s]*(?='\)]))/;
        unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $_)) {
            $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the $ind_" );
            print FH "STEP: Verify the $ind_ - Fail \n";
            $result = 0;
        } else {
            print FH "STEP: Verify the $ind_ - Pass \n";
        }      
    }
    #click Debug Configuration
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $deg_config)) {
        $logger->error(__PACKAGE__ . ": Failed to click 'Debug Configuration' button" );
        print FH "STEP: Click 'Debug Configuration' button - FAIL \n";
        return 0;
    } else {
        print FH "STEP: Click 'Debug Configuration' button - PASS \n";
    }
    #verify Debug Configuration
    foreach(@vrf_deg_config_){
        my ($deg_) = $_ =~ /((?<=\/\/div\[contains\(text\(\),')[A-Za-z\d\s]*(?='\)]))/;
        unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $_)) {
            $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the $deg_" );
            print FH "STEP: Verify the $deg_ - Fail \n";
            $result = 0;
        } else {
            print FH "STEP: Verify the $deg_ - Pass \n";
        }      
    }
    #click Congestion Configuration
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $cong_conf)) {
        $logger->error(__PACKAGE__ . ": Failed to click 'Congestion Configuration' button" );
        print FH "STEP: Click 'Congestion Configuration' button - FAIL \n";
        return 0;
    } else {
        print FH "STEP: Click 'Congestion Configuration' button - PASS \n";
    }
    #verify  Congestion Configuration
    foreach(@vrf_cong_conf_){
        my ($ind) = $_ =~ /((?<=\/\/div\[contains\(text\(\),')[A-Za-z\d\s]*(?='\)]))/;
        unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $_)) {
            $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the $ind" );
            print FH "STEP: Verify the $ind - Fail \n";
            $result = 0;
        } else {
            print FH "STEP: Verify the $ind - Pass \n";
        }      
    }
    #click SCTP Configuration
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $sctp_conf)) {
        $logger->error(__PACKAGE__ . ": Failed to click 'SCTP Configuration' button" );
        print FH "STEP: Click 'SCTP Configuration' button - FAIL \n";
        return 0;
    } else {
        print FH "STEP: Click 'SCTP Configuration' button - PASS \n";
    }
    #verify SCTP Configuration
    foreach(@vrf_sctp_conf_){
        my ($ind__) = $_ =~ /((?<=\/\/div\[contains\(text\(\),')[A-Za-z\d\s]*(?='\)]))/;
        unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $_)) {
            $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the $ind__" );
            print FH "STEP: Verify the $ind__ - Fail \n";
            $result = 0;
        } else {
            print FH "STEP: Verify the $ind__ - Pass \n";
        }      
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}


sub ADQ_1411_Auto_MTP3_29 { #Add Route
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_29");
    my $sub_name = "ADQ_1411_Auto_MTP3_29";
	my $tcid = "ADQ_1411_Auto_MTP3_29";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    #add NA
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Add M2PA Link
    unless(grep/:ADD-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-SLK::50-51.51.51-0:CTAG::::M2PA:DRE_ID=1;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add M2PA link by command 'ADD-SLK::50-51.51.51-0:CTAG::::M2PA:DRE_ID=1;'" );
        print FH "STEP: Add M2PA link by command 'ADD-SLK::50-51.51.51-0:CTAG::::M2PA:DRE_ID=1;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add M2PA link by command 'ADD-SLK::50-51.51.51-0:CTAG::::M2PA:DRE_ID=1;' - PASS \n";  
    }
    #add Routeset
    unless(grep/:ADD-RTESET:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;'  " );
        print FH "STEP: Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;' - PASS \n";  
    }
    #Add Route
    unless(grep/:ADD-RTE:COSTA:COMPLD;/,$ses_CLI1->execCmd("ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add ROUTE by command 'ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;'  " );
        print FH "STEP: Add ROUTE by command 'ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add ROUTE by command 'ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;' - PASS \n";  
    }
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_30 { #Change Route
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_30");
    my $sub_name = "ADQ_1411_Auto_MTP3_30";
	my $tcid = "ADQ_1411_Auto_MTP3_30";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #add Routeset
    unless(grep/:ADD-RTESET:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;'  " );
        print FH "STEP: Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Add Route
    unless(grep/:ADD-RTE:COSTA:COMPLD;/,$ses_CLI1->execCmd("ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add ROUTE by command 'ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;'  " );
        print FH "STEP: Add ROUTE by command 'ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add ROUTE by command 'ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;' - PASS \n";  
    }
    #Change Route
    unless(grep/:CHG-RTE:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG:::::COST=10;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change ROUTE by command 'CHG-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG:::::COST=10;'  " );
        print FH "STEP: Change ROUTE by command 'CHG-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG:::::COST=10;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change ROUTE by command 'CHG-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG:::::COST=10;' - PASS \n";  
    }
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";  
    my $xpath_routesets = "//span[contains(text(),'Routesets')]";  
    my $na50 = "//a[contains(text(),'NA 50')]";
    my $routeset_mrs_051 = "//a [contains (text(), 'MRS 0:051.051.051') ]";
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #click Routeset
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_routesets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Routesets'" );
        print FH "STEP: Click the 'Routesets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Routesets' - Pass \n";
    } 
    #click MRS 0:051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $routeset_mrs_051)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'MRS 0:051.051.051'" );
        print FH "STEP: Click the 'MRS 0:051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'MRS 0:051.051.051' - Pass \n";
    } 
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_31 { #Set Route
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_31");
    my $sub_name = "ADQ_1411_Auto_MTP3_31";
	my $tcid = "ADQ_1411_Auto_MTP3_31";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #add Routeset
    unless(grep/:ADD-RTESET:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;'  " );
        print FH "STEP: Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;' - PASS \n";  
    }
    #Add Route
    unless(grep/:ADD-RTE:COSTA:COMPLD;/,$ses_CLI1->execCmd("ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add ROUTE by command 'ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;'  " );
        print FH "STEP: Add ROUTE by command 'ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add ROUTE by command 'ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;' - PASS \n";  
    }
    #Set Route
    unless(grep/:SET-RTE:CTAG:COMPLD;/,$ses_CLI1->execCmd("SET-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG:::RESETSTATE;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Set ROUTE by command 'SET-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG:::RESETSTATE;'  " );
        print FH "STEP: Set ROUTE by command 'SET-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG:::RESETSTATE;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Set ROUTE by command 'SET-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG:::RESETSTATE;' - PASS \n";  
    }
   
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_32 { #Set Routeset
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_32");
    my $sub_name = "ADQ_1411_Auto_MTP3_32";
	my $tcid = "ADQ_1411_Auto_MTP3_32";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    #add NA
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #set NA
    unless(grep/:SET-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("SET-NA::$NA_50:CTAG:::ACT;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Enable NA by command 'SET-NA::$NA_50:CTAG:::ACT;'  " );
        print FH "STEP: Enable NA by command 'SET-NA::$NA_50:CTAG:::ACT;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Enable NA by command 'SET-NA::$NA_50:CTAG:::ACT;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Add M2PA Link
    unless(grep/:ADD-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-SLK::50-51.51.51-0:CTAG::::M2PA:DRE_ID=1;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add M2PA link by command 'ADD-SLK::50-51.51.51-0:CTAG::::M2PA:DRE_ID=1;'" );
        print FH "STEP: Add M2PA link by command 'ADD-SLK::50-51.51.51-0:CTAG::::M2PA:DRE_ID=1;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add M2PA link by command 'ADD-SLK::50-51.51.51-0:CTAG::::M2PA:DRE_ID=1;' - PASS \n";  
    }
    #Add Routeset
    unless(grep/:ADD-RTESET:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;'  " );
        print FH "STEP: Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;' - PASS \n";  
    }
    #Add Route
    unless(grep/:ADD-RTE:COSTA:COMPLD;/,$ses_CLI1->execCmd("ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add ROUTE by command 'ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;'  " );
        print FH "STEP: Add ROUTE by command 'ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add ROUTE by command 'ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;' - PASS \n";  
    }
    #Set Routeset
    unless(grep/:SET-RTESET:CTAG:COMPLD;/,$ses_CLI1->execCmd("SET-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG:::ACT;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Set Routeset by command 'SET-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG:::ACT;'  " );
        print FH "STEP: Set Routeset by command 'SET-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG:::ACT;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Set Routeset by command 'SET-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG:::ACT;' - PASS \n";  
    }
    
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";  
    my $xpath_routesets = "//span[contains(text(),'Routesets')]";  
    my $na50 = "//a[contains(text(),'NA 50')]";
    my $routeset_mrs_051 = "//a [contains (text(), 'MRS 0:051.051.051') ]";
    my $vrf_routeset_state = "//div[contains (text(),'Routeset State')]/ancestor::div//span[text()='ACTIVE']";
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
    my $xpath_ls = "//input[\@value= 'M2PA Link']/ancestor::div//input[\@title='Create M2PA Link']";
    my $xpath_ls_2 = "//a[text() = 'LS 051.051.051' ]";
    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #click linkset tab
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets'" );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }
    #click LS 051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets 051.051.051'" );
        print FH "STEP: Click the ' Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets 051.051.051' - Pass \n";
    }
   
    #click MTP3
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #click Routeset Tab
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_routesets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Routesets' tab" );
        print FH "STEP: Click the 'Routesets' tab - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Routesets' tab - Pass \n";
    } 
   
    #click MRS 0:051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $routeset_mrs_051)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'MRS 0:051.051.051'" );
        print FH "STEP: Click the 'MRS 0:051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'MRS 0:051.051.051' - Pass \n";
    } 
    #verfify routeset state
    unless (grep/ACTIVE/,$ses_Selenium->getText( -xPath => $vrf_routeset_state)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the Routeset State" );
        print FH "STEP: Verify the Routeset State - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the Routeset State - Pass \n";
    }  
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_33 { #Verify route
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_33");
    my $sub_name = "ADQ_1411_Auto_MTP3_33";
	my $tcid = "ADQ_1411_Auto_MTP3_33";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    #ADD NA
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #change linkset
    unless(grep/:CHG-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-LS::50-51.51.51:CTAG:::::CLLI=to51;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'CHG-LS::50-51.51.51:CTAG:::::CLLI=to51;'  " );
        print FH "STEP: Change LINKSET by command 'CHG-LS::50-51.51.51:CTAG:::::CLLI=to51;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change LINKSET by command CHG-LS::50-51.51.51:CTAG:::::CLLI=to51;' - PASS \n";  
    }
    #Add Routeset
    unless(grep/:ADD-RTESET:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;'  " );
        print FH "STEP: Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;' - PASS \n";  
    }
    #Add Route
    unless(grep/:ADD-RTE:COSTA:COMPLD;/,$ses_CLI1->execCmd("ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add ROUTE by command 'ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;'  " );
        print FH "STEP: Add ROUTE by command 'ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add ROUTE by command 'ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;' - PASS \n";  
    }
    #Change Route
    unless(grep/:CHG-RTE:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG:::::COST=10;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change ROUTE by command 'CHG-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG:::::COST=10;'  " );
        print FH "STEP: Change ROUTE by command 'CHG-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG:::::COST=10;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change ROUTE by command 'CHG-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG:::::COST=10;' - PASS \n";  
    }
    #Verify Route
    unless(grep/:VFY-RTE:CTAG:COMPLD/,$ses_CLI1->execCmd("VFY-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify ROUTER by command 'VFY-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG;'  " );
        print FH "STEP: Verify ROUTE by command 'VFY-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Verify ROUTE by command 'VFY-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG;' - PASS \n";  
    }
    
    ## Go to url 
    my ($sessionId, $localUrl);
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";  
    my $xpath_routesets = "//span[contains(text(),'Routesets')]";  
    my $na50 = "//a[contains(text(),'NA 50')]";
    my $routeset_mrs_051 = "//a [contains (text(), 'MRS 0:051.051.051') ]";
    my $routeset_state = "//div[contains (text(),'Routeset State')]/ancestor::div//span[text()='INACTIVE']";
    my $route_ls_051 = "//a[contains (text(),'RT LS 051.051.051')]";
    my $vrf_cost = "//div[contains (text(),'Cost')]/ancestor::div[1]//input[\@value='10']";
    my $vrf_clli_route = "//div[contains (text(),'CLLI')]/ancestor::div//span[text()='to51']";
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }

    #click Routeset
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_routesets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Routesets'" );
        print FH "STEP: Click the 'Routesets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Routesets' - Pass \n";
    } 
    #click MRS 0:051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $routeset_mrs_051)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'MRS 0:051.051.051'" );
        print FH "STEP: Click the 'MRS 0:051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'MRS 0:051.051.051' - Pass \n";
    } 
    #click RT LS 051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $route_ls_051)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'RT LS 051.051.051' tab" );
        print FH "STEP: Click 'RT LS 051.051.051' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'RT LS 051.051.051' tab - PASS \n";
    }   
    unless (grep/10/,$ses_Selenium->getAttribute( -xPath => $vrf_cost, -attribute => 'value')) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the Cost" );
        print FH "STEP: Verify the Cost - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the Cost - Pass \n";
    }    
    unless (grep/to51/,$ses_Selenium->getText( -xPath => $vrf_clli_route)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the CLLI" );
        print FH "STEP: Verify the CLLI - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the CLLI - Pass \n";
    }  
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}


sub ADQ_1411_Auto_MTP3_34 { #Verify Routeset
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_34");
    my $sub_name = "ADQ_1411_Auto_MTP3_34";
	my $tcid = "ADQ_1411_Auto_MTP3_34";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    #add NA
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Add Routeset
    unless(grep/:ADD-RTESET:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;'  " );
        print FH "STEP: Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;' - PASS \n";  
    }
    #change Routeset
    unless(grep/:CHG-RTESET:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG:::::CLLI=Autotest_RS1;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to change ROUTER by command 'CHG-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG:::::CLLI=Autotest_RS1;'  " );
        print FH "STEP: Change ROUTER by command 'CHG-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG:::::CLLI=Autotest_RS1;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change ROUTER by command 'CHG-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG:::::CLLI=Autotest_RS1;' - PASS \n";  
    }
    #Add Route
    unless(grep/:ADD-RTE:COSTA:COMPLD;/,$ses_CLI1->execCmd("ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add ROUTE by command 'ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;'  " );
        print FH "STEP: Add ROUTE by command 'ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add ROUTE by command 'ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;' - PASS \n";  
    }
    #Set Route
    unless(grep/:SET-RTE:CTAG:COMPLD;/,$ses_CLI1->execCmd("SET-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG:::RESETSTATE;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Set ROUTE by command 'SET-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG:::RESETSTATE;'  " );
        print FH "STEP: Set ROUTE by command 'SET-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG:::RESETSTATE;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Set ROUTE by command 'SET-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG:::RESETSTATE;' - PASS \n";  
    }
    #Set Routeset
    unless(grep/:SET-RTESET:CTAG:COMPLD;/,$ses_CLI1->execCmd("SET-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG:::ACT;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Set Routeset by command 'SET-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG:::ACT;'  " );
        print FH "STEP: Set Routeset by command 'SET-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG:::ACT;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Set Routeset by command 'SET-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG:::ACT;' - PASS \n";  
    }
    #Verify Routeset
    unless(grep/:VFY-RTESET:CTAG:COMPLD/,$ses_CLI1->execCmd("VFY-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify Routeset by command 'VFY-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;'  " );
        print FH "STEP: Verify Routeset by command VFY-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Verify Routeset by command 'VFY-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;' - PASS \n";  
    }
    
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";  
    my $xpath_routesets = "//span[contains(text(),'Routesets')]";  
    my $xpath_mrs = "//a[text()='MRS 0:051.051.051']";
    my $na50 = "//a[contains(text(),'NA 50')]";
    my $routeset_mrs_051 = "//a [contains (text(), 'MRS 0:051.051.051') ]";
    my $route_ls_051 = "//a[contains (text(),'RT LS 051.051.051')]";
    #verify xpath
    my (@vrf_rts_, $ind_);
    $vrf_rts_[$ind_++] = "//div[contains (text(),'Context')]/ancestor::div//span[text()='MRS 0\:051.051.051']";
    $vrf_rts_[$ind_++] = "//div[contains (text(),'Destination Type')]/ancestor::div//span[text()='MEMBER']";
    $vrf_rts_[$ind_++] = "//div[contains (text(),'CLLI')]/ancestor::div//input[\@value='Autotest_RS1']";
    $vrf_rts_[$ind_++] = "//div[contains (text(),'Routeset State')]/ancestor::div//span[text()='ACTIVE']";
    $vrf_rts_[$ind_++] = "//div[contains (text(),'Congestion Level')]/ancestor::div[1]//span[text()='FALSE']";
    $vrf_rts_[$ind_++] = "//div[contains (text(),'Destination State')]/ancestor::div[1]//span[text()='INACCESSIBLE']";
    $vrf_rts_[$ind_++] = "//div[contains (text(),'Broadcast TCA')]/ancestor::div[1]//option[\@value='ENABLED']";
    $vrf_rts_[$ind_++] = "//div[contains (text(),'Broadcast TCP')]/ancestor::div[1]//option[\@value='ENABLED']";
    $vrf_rts_[$ind_++] = "//div[contains (text(),'Broadcast TCR')]/ancestor::div[1]//option[\@value='ENABLED']";
    $vrf_rts_[$ind_++] = "//div[contains (text(),'Broadcast TFA')]/ancestor::div[1]//option[\@value='ENABLED']";
    $vrf_rts_[$ind_++] = "//div[contains (text(),'Broadcast TFP')]/ancestor::div[1]//option[\@value='ENABLED']";
    $vrf_rts_[$ind_++] = "//div[contains (text(),'Broadcast TFR')]/ancestor::div[1]//option[\@value='ENABLED']";
    $vrf_rts_[$ind_++] = "//div[contains (text(),'Congestion Notif of UPs')]/ancestor::div[1]//input[\@value='8']";
    $vrf_rts_[$ind_++] = "//div[contains (text(),'Allow X-Routesets')]/ancestor::div[1]//option[\@value='DISABLED']";
    $vrf_rts_[$ind_++] = "//div[contains (text(),'Test State')]/ancestor::div[1]//span[text()='IDLE']";
    $vrf_rts_[$ind_++] = "//div[contains (text(),'Routeset ID')]/ancestor::div[1]//input[\@value='UNDEFINED']";
    $vrf_rts_[$ind_++] = "//div[contains (text(),'Loadshare Mode')]/ancestor::div[1]//option[\@value='NODE_VALUE']";
    $vrf_rts_[$ind_++] = "//div[contains (text(),'Alarms')]/ancestor::div[1]//option[\@value='ENABLED']";

   
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #click Routeset
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_routesets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Routesets'" );
        print FH "STEP: Click the 'Routesets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Routesets' - Pass \n";
    } 
    #click MRS 0:051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_mrs)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'MRS 0:051.051.051'" );
        print FH "STEP: Click the 'MRS 0:051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'MRS 0:051.051.051' - Pass \n";
    } 
    #verify rts
    sleep(5);
    foreach (@vrf_rts_){
        my ($ind_) = $_ =~ /((?<=\/\/div\[contains\s\(text\(\),')[A-Za-z\d\s]*)/;
        unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $_)) {
            $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the $ind_" );
            print FH "STEP: Verify the $ind_ - Fail \n";
            $result = 0;
        } else {
            print FH "STEP: Verify the $ind_ - Pass \n";
        }       
    }

############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_35 { #Delete Route
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_35");
    my $sub_name = "ADQ_1411_Auto_MTP3_35";
	my $tcid = "ADQ_1411_Auto_MTP3_35";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    #add NA
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Add Routeset
    unless(grep/:ADD-RTESET:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;'  " );
        print FH "STEP: Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;' - PASS \n";  
    }
    #Add Route
    unless(grep/:ADD-RTE:COSTA:COMPLD;/,$ses_CLI1->execCmd("ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add ROUTE by command 'ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;'" );
        print FH "STEP: Add ROUTE by command 'ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add ROUTE by command 'ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;' - PASS \n";  
    }
    #Delete Route
    unless(grep/:DLT-RTE:CTAG:COMPLD;/,$ses_CLI1->execCmd("DLT-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Delete ROUTE by command 'DLT-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG;'" );
        print FH "STEP: Delete ROUTE by command 'DLT-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Delete ROUTE by command 'DLT-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG;' - PASS \n";  
    }

    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";  
    my $xpath_routesets = "//span[contains(text(),'Routesets')]";  
    my $xpath_mrs = "//a[text()='MRS 0:051.051.051']";
    my $na50 = "//a[contains(text(),'NA 50')]";
    my $routeset_mrs_051 = "//a [contains (text(), 'MRS 0:051.051.051') ]";   
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #click Routeset
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_routesets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Routesets'" );
        print FH "STEP: Click the 'Routesets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Routesets' - Pass \n";
    } 
    #click MRS 0:051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_mrs)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'MRS 0:051.051.051'" );
        print FH "STEP: Click the 'MRS 0:051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'MRS 0:051.051.051' - Pass \n";
    } 
   
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_36 { #Delete Routeset
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_36");
    my $sub_name = "ADQ_1411_Auto_MTP3_36";
	my $tcid = "ADQ_1411_Auto_MTP3_36";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    #add NA
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Add Routeset
    unless(grep/:ADD-RTESET:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;'  " );
        print FH "STEP: Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add ROUTER by command 'ADD-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;' - PASS \n";  
    }
    #Add Route
    unless(grep/:ADD-RTE:COSTA:COMPLD;/,$ses_CLI1->execCmd("ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add ROUTE by command 'ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;'  " );
        print FH "STEP: Add ROUTE by command 'ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add ROUTE by command 'ADD-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:COSTA:::::COST=0;' - PASS \n";  
    }
    #Delete Route
    unless(grep/:DLT-RTE:CTAG:COMPLD;/,$ses_CLI1->execCmd("DLT-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Delete ROUTE by command 'DLT-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG;'  " );
        print FH "STEP: Delete ROUTE by command 'DLT-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Delete ROUTE by command 'DLT-RTE::50-STANDARD-51.51.51-MEMBER-51.51.51:CTAG;' - PASS \n";  
    }
    #Delete Linkset
    unless(grep/:DLT-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("DLT-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Delete ROUTE by command 'DLT-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Delete ROUTE by command 'DLT-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Delete ROUTE by command 'DLT-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Delete Routeset
    unless(grep/:DLT-RTESET:CTAG:COMPLD;/,$ses_CLI1->execCmd("DLT-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Delete ROUTE by command 'DLT-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;'  " );
        print FH "STEP: Delete ROUTESET by command 'DLT-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Delete ROUTESET by command 'DLT-RTESET::50-STANDARD-51.51.51-MEMBER:CTAG;' - PASS \n";  
    }
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";  
    my $xpath_routesets = "//span[contains(text(),'Routesets')]";  
    my $xpath_mrs = "//a[text()='MRS 0:051.051.051']";
    my $na50 = "//a[contains(text(),'NA 50')]";
    my $routeset_mrs_051 = "//a [contains (text(), 'MRS 0:051.051.051') ]";   
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #click Routeset
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_routesets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Routesets'" );
        print FH "STEP: Click the 'Routesets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Routesets' - Pass \n";
    } 
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_37 { #Delete Link
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_37");
    my $sub_name = "ADQ_1411_Auto_MTP3_37";
	my $tcid = "ADQ_1411_Auto_MTP3_37";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    #add NA
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Add M2PA Link
    unless(grep/:ADD-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-SLK::50-51.51.51-0:CTAG::::M2PA:DRE_ID=1;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add M2PA link by command 'ADD-SLK::50-51.51.51-0:CTAG::::M2PA:DRE_ID=1;'" );
        print FH "STEP: Add M2PA link by command 'ADD-SLK::50-51.51.51-0:CTAG::::M2PA:DRE_ID=1;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add M2PA link by command 'ADD-SLK::50-51.51.51-0:CTAG::::M2PA:DRE_ID=1;' - PASS \n";  
    }
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";  
    my $xpath_routesets = "//span[contains(text(),'Routesets')]";  
    my $xpath_mrs = "//a[text()='MRS 0:051.051.051']";
    my $na50 = "//a[contains(text(),'NA 50')]";
    my $routeset_mrs_051 = "//a [contains (text(), 'MRS 0:051.051.051') ]"; 
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]"; 
    my $xpath_ls_2 = "//a[text() = 'LS 051.051.051' ]"; 
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #click Linkset tab
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Linksets' tab" );
        print FH "STEP: Click the 'Linksets' tab - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Linksets' tab - Pass \n";
    }
    #click LS 051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Linksets 051.051.051'" );
        print FH "STEP: Click the ' Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets 051.051.051' - Pass \n";
    }
  
    #Delete M2PA Link
    unless(grep/:DLT-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("DLT-SLK::50-51.51.51-0:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Delete LINK by command 'DLT-SLK::50-51.51.51-0:CTAG;'  " );
        print FH "STEP: Delete LINK by command 'DLT-SLK::50-51.51.51-0:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Delete LINK by command 'DLT-SLK::50-51.51.51-0:CTAG;' - PASS \n";  
    }

############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_38 { #Delete Linkset
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_38");
    my $sub_name = "ADQ_1411_Auto_MTP3_38";
	my $tcid = "ADQ_1411_Auto_MTP3_38";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    #add NA
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #delete Linkset
    unless(grep/:DLT-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("DLT-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'DLT-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'DLT-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'DLT-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
   
     ## Go to url 
    my ($sessionId, $localUrl);
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";  
    my $na50 = "//a[contains(text(),'NA 50')]";
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #click Linkset tab
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets'" );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }


   

############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_39 { #Add a PC mapping
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_39");
    my $sub_name = "ADQ_1411_Auto_MTP3_39";
	my $tcid = "ADQ_1411_Auto_MTP3_39";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    #add NA
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Add a PC mapping
    unless(grep/:ADD-PCMAP:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-PCMAP::50-Autotest_mapping:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }

    ## Go to url 
    my ($sessionId, $localUrl);
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";  
    my $na50 = "//a[contains(text(),'NA 50')]";
    my $xpath_pc_mapping ="//span[contains (text(),'PC Mappings')]";
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #click PC Mappings tab
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_pc_mapping)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'PC Mappings'" );
        print FH "STEP: Click the 'PC Mappings' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'PC Mappings' - Pass \n";
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_40 { #Add a PC mapping
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_40");
    my $sub_name = "ADQ_1411_Auto_MTP3_40";
	my $tcid = "ADQ_1411_Auto_MTP3_40";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    #add NA
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add a PC mapping
    unless(grep/:ADD-PCMAP:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-PCMAP::50-Autotest_mapping:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Verify a PC mapping
    unless(grep/:VFY-PCMAP:CTAG:COMPLD/,$ses_CLI1->execCmd("VFY-PCMAP::50-Autotest_mapping:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify PC mapping by command 'VFY-PCMAP::50-Autotest_mapping:CTAG;'  " );
        print FH "STEP: Verify PC mapping by command 'VFY-PCMAP::50-Autotest_mapping:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Verify PC mapping by command 'VFY-PCMAP::50-Autotest_mapping:CTAG;' - PASS \n";  
    }

    ## Go to url 
    my ($sessionId, $localUrl);
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";  
    my $na50 = "//a[contains(text(),'NA 50')]";
    my $xpath_pc_mapping ="//span[contains (text(),'PC Mappings')]";
    my $xpath_auto_map = "//a[text()='Autotest_mapping']";
    my $vrf_pc_map_name ="//div[contains (text(),'PC Mapping Name')]/ancestor::div//span[text()='Autotest_mapping']";
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #click PC Mappings tab
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_pc_mapping)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'PC Mappings'" );
        print FH "STEP: Click the 'PC Mappings' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'PC Mappings' - Pass \n";
    }
    #click Autotest Mapping
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_auto_map)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Autotest Mapping'" );
        print FH "STEP: Click the 'Autotest Mapping' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Autotest Mapping' - Pass \n";
    }
    #verify
    unless (grep/Autotest_mapping/,$ses_Selenium->getText( -xPath => $vrf_pc_map_name)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the PC Mapping Name" );
        print FH "STEP: Verify the PC Mapping Name - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the PC Mapping Name - Pass \n";
    }  
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_41 { #Delete a PC mapping
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_41");
    my $sub_name = "ADQ_1411_Auto_MTP3_41";
	my $tcid = "ADQ_1411_Auto_MTP3_41";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    #add NA
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add A PC mapping
    unless(grep/:ADD-PCMAP:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-PCMAP::50-Autotest_mapping:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
   
    ## Go to url 
    my ($sessionId, $localUrl);
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";  
    my $na50 = "//a[contains(text(),'NA 50')]";
    my $xpath_pc_mapping ="//span[contains (text(),'PC Mappings')]";
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #click PC Mappings tab
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_pc_mapping)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'PC Mappings'" );
        print FH "STEP: Click the 'PC Mappings' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'PC Mappings' - Pass \n";
    }
    #Delete a PC mapping
    unless(grep/:DLT-PCMAP:CTAG:COMPLD;/,$ses_CLI1->execCmd("DLT-PCMAP::50-Autotest_mapping:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Delete PC mapping by command 'DLT-PCMAP::50-Autotest_mapping:CTAG;'  " );
        print FH "STEP: Delete PC mapping by command 'DLT-PCMAP::50-Autotest_mapping:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Delete PC mapping by command 'DLT-PCMAP::50-Autotest_mapping:CTAG;' - PASS \n";  
    }

############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_42 { #Add PC Mapping record
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_42");
    my $sub_name = "ADQ_1411_Auto_MTP3_42";
	my $tcid = "ADQ_1411_Auto_MTP3_42";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    #add NA
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add a PC mapping
    unless(grep/:ADD-PCMAP:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-PCMAP::50-Autotest_mapping:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Add PC Mapping record
    unless(grep/:ADD-PCMAPREC:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-PCMAPREC::50-Autotest_mapping-ANY-1.2.4-4.3.2:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add PC mapping record by command 'ADD-PCMAPREC::50-Autotest_mapping-ANY-1.2.4-4.3.2:CTAG;'  " );
        print FH "STEP: Add PC mapping record by command 'ADD-PCMAPREC::50-Autotest_mapping-ANY-1.2.4-4.3.2:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add PC mapping record by command 'ADD-PCMAPREC::50-Autotest_mapping-ANY-1.2.4-4.3.2:CTAG;' - PASS \n";  
    }

    ## Go to url 
    my ($sessionId, $localUrl);
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";  
    my $na50 = "//a[contains(text(),'NA 50')]";
    my $xpath_pc_mapping ="//span[contains (text(),'PC Mappings')]";
    my $xpath_auto_map = "//a[text()='Autotest_mapping']";
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #click PC Mappings tab
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_pc_mapping)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'PC Mappings'" );
        print FH "STEP: Click the 'PC Mappings' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'PC Mappings' - Pass \n";
    }
    #click Autotest Mapping
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_auto_map)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Autotest Mapping'" );
        print FH "STEP: Click the 'Autotest Mapping' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Autotest Mapping' - Pass \n";
    }
    
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_43 { #Change PC Mapping record
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_43");
    my $sub_name = "ADQ_1411_Auto_MTP3_43";
	my $tcid = "ADQ_1411_Auto_MTP3_43";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    #add NA
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add a PC mapping
    unless(grep/:ADD-PCMAP:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-PCMAP::50-Autotest_mapping:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Add PC Mapping record
    unless(grep/:ADD-PCMAPREC:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-PCMAPREC::50-Autotest_mapping-ANY-1.2.4-4.3.2:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add PC mapping record by command 'ADD-PCMAPREC::50-Autotest_mapping-ANY-1.2.4-4.3.2:CTAG;'  " );
        print FH "STEP: Add PC mapping record by command 'ADD-PCMAPREC::50-Autotest_mapping-ANY-1.2.4-4.3.2:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add PC mapping record by command 'ADD-PCMAPREC::50-Autotest_mapping-ANY-1.2.4-4.3.2:CTAG;' - PASS \n";  
    }
    #Change PC Mapping record
    unless(grep/:CHG-PCMAPREC:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-PCMAPREC::50-Autotest_mapping-ANY-001.002.004-004.003.002:CTAG:::::DIR=INCOMING,LOCAL_PC=001.002.005,RPC=004.003.005;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change PC mapping record by command 'CHG-PCMAPREC::50-Autotest_mapping-ANY-001.002.004-004.003.002:CTAG:::::DIR=INCOMING,LOCAL_PC=001.002.005,RPC=004.003.005;'  " );
        print FH "STEP: Change PC mapping record by command 'CHG-PCMAPREC::50-Autotest_mapping-ANY-001.002.004-004.003.002:CTAG:::::DIR=INCOMING,LOCAL_PC=001.002.005,RPC=004.003.005;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change PC mapping record by command 'CHG-PCMAPREC::50-Autotest_mapping-ANY-001.002.004-004.003.002:CTAG:::::DIR=INCOMING,LOCAL_PC=001.002.005,RPC=004.003.005;' - PASS \n";  
    }
    ## Go to url 
    my ($sessionId, $localUrl);
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";  
    my $na50 = "//a[contains(text(),'NA 50')]";
    my $xpath_pc_mapping ="//span[contains (text(),'PC Mappings')]";
    my $xpath_auto_map = "//a[text()='Autotest_mapping']";
    my $xpath_pc_mapping_record = "//a[text()='INCOMING']";
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #click PC Mappings tab
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_pc_mapping)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'PC Mappings'" );
        print FH "STEP: Click the 'PC Mappings' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'PC Mappings' - Pass \n";
    }
    #click Autotest Mapping
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_auto_map)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Autotest Mapping'" );
        print FH "STEP: Click the 'Autotest Mapping' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Autotest Mapping' - Pass \n";
    }
    #click Autotest Mapping Record
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_pc_mapping_record)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Autotest Mapping Record'" );
        print FH "STEP: Click the 'Autotest Mapping Record' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Autotest Mapping Record' - Pass \n";
    }

    
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_44 { #Verify PC Mapping record
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_44");
    my $sub_name = "ADQ_1411_Auto_MTP3_44";
	my $tcid = "ADQ_1411_Auto_MTP3_44";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    #add NA
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add a PC mapping
    unless(grep/:ADD-PCMAP:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-PCMAP::50-Autotest_mapping:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Add PC Mapping record
    unless(grep/:ADD-PCMAPREC:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-PCMAPREC::50-Autotest_mapping-ANY-1.2.4-4.3.2:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add PC mapping record by command 'ADD-PCMAPREC::50-Autotest_mapping-ANY-1.2.4-4.3.2:CTAG;'  " );
        print FH "STEP: Add PC mapping record by command 'ADD-PCMAPREC::50-Autotest_mapping-ANY-1.2.4-4.3.2:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add PC mapping record by command 'ADD-PCMAPREC::50-Autotest_mapping-ANY-1.2.4-4.3.2:CTAG;' - PASS \n";  
    }
    #Verify PC Mapping record
    unless(grep/:VFY-PCMAPREC:CTAG:COMPLD/,$ses_CLI1->execCmd("VFY-PCMAPREC::50-Autotest_mapping-ANY-001.002.004-004.003.002:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify PC mapping record by command 'VFY-PCMAPREC::50-Autotest_mapping-ANY-001.002.004-004.003.002:CTAG;'  " );
        print FH "STEP: Verify PC mapping record by command 'VFY-PCMAPREC::50-Autotest_mapping-ANY-001.002.004-004.003.002:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Verify PC mapping record by command 'VFY-PCMAPREC::50-Autotest_mapping-ANY-001.002.004-004.003.002:CTAG;' - PASS \n";  
    }
    ## Go to url 
    my ($sessionId, $localUrl);
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";  
    my $na50 = "//a[contains(text(),'NA 50')]";
    my $xpath_pc_mapping ="//span[contains (text(),'PC Mappings')]";
    my $xpath_auto_map = "//a[text()='Autotest_mapping']";
    my $xpath_pc_mapping_record = "//a[text()='ANY']";
    #verify 
    my $vrf_direc_map_record = "//div[contains (text(), 'Direction')]/ancestor::div//option[\@value='ANY']";
    my $vrf_local_pc_map_record = "//div[contains (text(), 'Local PC')]/ancestor::div//input[\@value='001.002.004']";
    my $vrf_remote_pc_map_record = "//div[contains (text(), 'Remote PC')]/ancestor::div//input[\@value='004.003.002']";
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #click PC Mappings tab
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_pc_mapping)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'PC Mappings'" );
        print FH "STEP: Click the 'PC Mappings' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'PC Mappings' - Pass \n";
    }
    #click Autotest Mapping
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_auto_map)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Autotest Mapping'" );
        print FH "STEP: Click the 'Autotest Mapping' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Autotest Mapping' - Pass \n";
    }
    #click Autotest Mapping Record
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_pc_mapping_record)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Autotest Mapping Record'" );
        print FH "STEP: Click the 'Autotest Mapping Record' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Autotest Mapping Record' - Pass \n";
    }
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_direc_map_record)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the Direction" );
        print FH "STEP: Verify the Direction - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the Direction - Pass \n";
    }   
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_local_pc_map_record)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the Local PC" );
        print FH "STEP: Verify the Local PC - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the Local PC - Pass \n";
    } 
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_remote_pc_map_record)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the Remote PC" );
        print FH "STEP: Verify the Remote PC - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the Remote PC - Pass \n";
    } 

    
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_45 { #Delete PC Mapping record
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_45");
    my $sub_name = "ADQ_1411_Auto_MTP3_45";
	my $tcid = "ADQ_1411_Auto_MTP3_45";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    #add NA
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add a PC mapping
    unless(grep/:ADD-PCMAP:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-PCMAP::50-Autotest_mapping:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Add PC Mapping record
    unless(grep/:ADD-PCMAPREC:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-PCMAPREC::50-Autotest_mapping-ANY-1.2.4-4.3.2:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add PC mapping record by command 'ADD-PCMAPREC::50-Autotest_mapping-ANY-1.2.4-4.3.2:CTAG;'  " );
        print FH "STEP: Add PC mapping record by command 'ADD-PCMAPREC::50-Autotest_mapping-ANY-1.2.4-4.3.2:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add PC mapping record by command 'ADD-PCMAPREC::50-Autotest_mapping-ANY-1.2.4-4.3.2:CTAG;' - PASS \n";  
    }
    #Change PC Mapping record
    unless(grep/:CHG-PCMAPREC:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-PCMAPREC::50-Autotest_mapping-ANY-001.002.004-004.003.002:CTAG:::::DIR=INCOMING,LOCAL_PC=001.002.005,RPC=004.003.005;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change PC mapping record by command 'CHG-PCMAPREC::50-Autotest_mapping-ANY-001.002.004-004.003.002:CTAG:::::DIR=INCOMING,LOCAL_PC=001.002.005,RPC=004.003.005;'  " );
        print FH "STEP: Change PC mapping record by command 'CHG-PCMAPREC::50-Autotest_mapping-ANY-001.002.004-004.003.002:CTAG:::::DIR=INCOMING,LOCAL_PC=001.002.005,RPC=004.003.005;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change PC mapping record by command 'CHG-PCMAPREC::50-Autotest_mapping-ANY-001.002.004-004.003.002:CTAG:::::DIR=INCOMING,LOCAL_PC=001.002.005,RPC=004.003.005;' - PASS \n";  
    }

    ## Go to url 
    my ($sessionId, $localUrl);
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";  
    my $na50 = "//a[contains(text(),'NA 50')]";
    my $xpath_pc_mapping ="//span[contains (text(),'PC Mappings')]";
    my $xpath_auto_map = "//a[text()='Autotest_mapping']";
    my $xpath_pc_mapping_record = "//a[text()='ANY']";
  
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #click PC Mappings tab
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_pc_mapping)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'PC Mappings'" );
        print FH "STEP: Click the 'PC Mappings' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'PC Mappings' - Pass \n";
    }
    #click Autotest Mapping
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_auto_map)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Autotest Mapping'" );
        print FH "STEP: Click the 'Autotest Mapping' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Autotest Mapping' - Pass \n";
    }
    #Delete PC Mapping record
    unless(grep/:DLT-PCMAPREC:CTAG:COMPLD;/,$ses_CLI1->execCmd("DLT-PCMAPREC::50-Autotest_mapping-INCOMING-001.002.005-004.003.005:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Delete PC mapping record by command 'DLT-PCMAPREC::50-Autotest_mapping-INCOMING-001.002.005-004.003.005:CTAG;' " );
        print FH "STEP: Delete PC mapping record by command 'DLT-PCMAPREC::50-Autotest_mapping-INCOMING-001.002.005-004.003.005:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Delete PC mapping record by command 'ADD-PCMAPREC::50-Autotest_mapping-ANY-1.2.4-4.3.2:CTAG;' - PASS \n";  
    }
############################ CLEANUP #############################
    CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}


sub ADQ_1411_Auto_MTP3_46 { #Add migrate record 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_46");
    my $sub_name = "ADQ_1411_Auto_MTP3_46";
	my $tcid = "ADQ_1411_Auto_MTP3_46";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    #add NA
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add a PC mapping
    unless(grep/:ADD-PCMAP:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-PCMAP::50-Autotest_mapping:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Add migrate record 
    unless(grep/:ADD-MIGREC:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG:::::NEWDPC=007.007.007;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add migrate record by command 'ADD-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG:::::NEWDPC=007.007.007;'  " );
        print FH "STEP: Add migrate record by command 'ADD-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG:::::NEWDPC=007.007.007;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add migrate record by command 'ADD-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG:::::NEWDPC=007.007.007;' - PASS \n";  
    }

    ## Go to url 
    my ($sessionId, $localUrl);
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";  
    my $na50 = "//a[contains(text(),'NA 50')]";
    my $xpath_pc_mapping ="//span[contains (text(),'PC Mappings')]";
    my $xpath_auto_map = "//a[text()='Autotest_mapping']";
    my $xpath_pc_mapping_record = "//a[text()='ANY']";
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #click PC Mappings tab
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_pc_mapping)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'PC Mappings'" );
        print FH "STEP: Click the 'PC Mappings' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'PC Mappings' - Pass \n";
    }
    #click Autotest Mapping
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_auto_map)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Autotest Mapping'" );
        print FH "STEP: Click the 'Autotest Mapping' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Autotest Mapping' - Pass \n";
    }
############################ CLEANUP #############################
    CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_47 { #Change migrate record 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_47");
    my $sub_name = "ADQ_1411_Auto_MTP3_47";
	my $tcid = "ADQ_1411_Auto_MTP3_47";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    #add NA
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add a PC mapping
    unless(grep/:ADD-PCMAP:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-PCMAP::50-Autotest_mapping:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Add migrate record 
    unless(grep/:ADD-MIGREC:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG:::::NEWDPC=007.007.007;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add migrate record by command 'ADD-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG:::::NEWDPC=007.007.007;'  " );
        print FH "STEP: Add migrate record by command 'ADD-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG:::::NEWDPC=007.007.007;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add migrate record by command 'ADD-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG:::::NEWDPC=007.007.007;' - PASS \n";  
    }
    #change migration record
    unless(grep/:CHG-MIGREC:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG:::::OPC=050.050.050,DPC=060.060.060,MSGCAT=AM Messages,NEWDPC=070.070.070;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change migrate record by command 'CHG-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG:::::OPC=050.050.050,DPC=060.060.060,MSGCAT=AM Messages,NEWDPC=070.070.070;'  " );
        print FH "STEP: Change migrate record by command 'CHG-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG:::::OPC=050.050.050,DPC=060.060.060,MSGCAT=AM Messages,NEWDPC=070.070.070;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change migrate record by command 'CHG-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG:::::OPC=050.050.050,DPC=060.060.060,MSGCAT=AM Messages,NEWDPC=070.070.070;' - PASS \n";  
    }

    ## Go to url 
    my ($sessionId, $localUrl);
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";  
    my $na50 = "//a[contains(text(),'NA 50')]";
    my $xpath_pc_mapping ="//span[contains (text(),'PC Mappings')]";
    my $xpath_auto_map = "//a[text()='Autotest_mapping']";
    my $xpath_pc_mapping_record = "//a[text()='ANY']";
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #click PC Mappings tab
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_pc_mapping)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'PC Mappings'" );
        print FH "STEP: Click the 'PC Mappings' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'PC Mappings' - Pass \n";
    }
    #click Autotest Mapping
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_auto_map)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Autotest Mapping'" );
        print FH "STEP: Click the 'Autotest Mapping' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Autotest Mapping' - Pass \n";
    }
   
############################ CLEANUP #############################
    CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_48 { #Verify migrate record 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_48");
    my $sub_name = "ADQ_1411_Auto_MTP3_48";
	my $tcid = "ADQ_1411_Auto_MTP3_48";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    #add NA
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add a PC mapping
    unless(grep/:ADD-PCMAP:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-PCMAP::50-Autotest_mapping:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Add migrate record 
    unless(grep/:ADD-MIGREC:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG:::::NEWDPC=007.007.007;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add migrate record by command 'ADD-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG:::::NEWDPC=007.007.007;'  " );
        print FH "STEP: Add migrate record by command 'ADD-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG:::::NEWDPC=007.007.007;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add migrate record by command 'ADD-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG:::::NEWDPC=007.007.007;' - PASS \n";  
    }
    #verify migration record
    unless(grep/:VFY-MIGREC:CTAG:COMPLD/,$ses_CLI1->execCmd("VFY-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify migrate record by command 'VFY-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG;'  " );
        print FH "STEP: Verify migrate record by command 'VFY-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Verify migrate record by command 'VFY-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG;' - PASS \n";  
    }

    ## Go to url 
    my ($sessionId, $localUrl);
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";  
    my $na50 = "//a[contains(text(),'NA 50')]";
    my $xpath_pc_mapping ="//span[contains (text(),'PC Mappings')]";
    my $xpath_auto_map = "//a[text()='Autotest_mapping']";
    my $xpath_pc_mapping_record = "//a[text()='ANY']";
    #verify
    my $vrf_opc = "//a[text()='005.005.005']";
    my $vrf_dpc = "//td[text()='006.006.006']";
    my $vrf_mess_cate = "//td[text()='AM Messages']";
    my $vrf_new_dpc = "//td[text()='007.007.007']";
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #click PC Mappings tab
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_pc_mapping)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'PC Mappings'" );
        print FH "STEP: Click the 'PC Mappings' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'PC Mappings' - Pass \n";
    }
    #click Autotest Mapping
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_auto_map)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Autotest Mapping'" );
        print FH "STEP: Click the 'Autotest Mapping' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Autotest Mapping' - Pass \n";
    }
    #verify
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_opc)) {
        $logger->error(__PACKAGE__ . ".$tcid: Faild to Verify the OPC" );
        print FH "STEP: Verify the OPC - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the OPC - Pass \n";
    }
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_dpc)) {
        $logger->error(__PACKAGE__ . ".$tcid: Faild to Verify the DPC" );
        print FH "STEP: Verify the DPC - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the DPC - Pass \n";
    }
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_mess_cate)) {
        $logger->error(__PACKAGE__ . ".$tcid: Faild to Verify the Message Category" );
        print FH "STEP: Verify the Message Category - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the Message Category - Pass \n";
    }
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_new_dpc)) {
        $logger->error(__PACKAGE__ . ".$tcid: Faild to Verify the New DPC" );
        print FH "STEP: Verify the New DPC - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the New DPC - Pass \n";
    }
############################ CLEANUP #############################
    CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_49 { #Delete migrate record 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_49");
    my $sub_name = "ADQ_1411_Auto_MTP3_49";
	my $tcid = "ADQ_1411_Auto_MTP3_49";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    #add NA
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add a PC mapping
    unless(grep/:ADD-PCMAP:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-PCMAP::50-Autotest_mapping:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Add migrate record 
    unless(grep/:ADD-MIGREC:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG:::::NEWDPC=007.007.007;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add migrate record by command 'ADD-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG:::::NEWDPC=007.007.007;'  " );
        print FH "STEP: Add migrate record by command 'ADD-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG:::::NEWDPC=007.007.007;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add migrate record by command 'ADD-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG:::::NEWDPC=007.007.007;' - PASS \n";  
    }

    ## Go to url 
    my ($sessionId, $localUrl);
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";  
    my $na50 = "//a[contains(text(),'NA 50')]";
    my $xpath_pc_mapping ="//span[contains (text(),'PC Mappings')]";
    my $xpath_auto_map = "//a[text()='Autotest_mapping']";
    my $xpath_pc_mapping_record = "//a[text()='ANY']";

    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #click PC Mappings tab
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_pc_mapping)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'PC Mappings'" );
        print FH "STEP: Click the 'PC Mappings' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'PC Mappings' - Pass \n";
    }
    #click Autotest Mapping
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_auto_map)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Autotest Mapping'" );
        print FH "STEP: Click the 'Autotest Mapping' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Autotest Mapping' - Pass \n";
    }
    #Delete migration record
    unless(grep/:DLT-MIGREC:CTAG:COMPLD;/,$ses_CLI1->execCmd("DLT-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Delete migrate record by command 'DLT-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG;'  " );
        print FH "STEP: Delete migrate record by command 'DLT-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Delete migrate record by command 'DLT-MIGREC::50-Autotest_mapping-005.005.005-006.006.006-AM Messages:CTAG;' - PASS \n";  
    }
    
############################ CLEANUP #############################
    CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_50 { #Delete migrate record 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_50");
    my $sub_name = "ADQ_1411_Auto_MTP3_50";
	my $tcid = "ADQ_1411_Auto_MTP3_50";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    #add NA
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add a PC mapping
    unless(grep/:ADD-PCMAP:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-PCMAP::50-Autotest_mapping:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Add Local Redirect Record 
    unless(grep/:ADD-LOCALREDREC:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LOCALREDREC::50-Autotest_mapping-002.002.002-FCM:CTAG:::::NEWDPC=003.003.003,MOD=Duplicate;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add Local Redirect Record by command 'ADD-LOCALREDREC::50-Autotest_mapping-002.002.002-FCM:CTAG:::::NEWDPC=003.003.003,MOD=Duplicate;'  " );
        print FH "STEP: Add Local Redirect Record by command 'ADD-LOCALREDREC::50-Autotest_mapping-002.002.002-FCM:CTAG:::::NEWDPC=003.003.003,MOD=Duplicate;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add Local Redirect Record by command 'ADD-LOCALREDREC::50-Autotest_mapping-002.002.002-FCM:CTAG:::::NEWDPC=003.003.003,MOD=Duplicate;' - PASS \n";  
    }

    ## Go to url 
    my ($sessionId, $localUrl);
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";  
    my $na50 = "//a[contains(text(),'NA 50')]";
    my $xpath_pc_mapping ="//span[contains (text(),'PC Mappings')]";
    my $xpath_auto_map = "//a[text()='Autotest_mapping']";
    my $xpath_pc_mapping_record = "//a[text()='ANY']";

    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #click PC Mappings tab
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_pc_mapping)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'PC Mappings'" );
        print FH "STEP: Click the 'PC Mappings' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'PC Mappings' - Pass \n";
    }
    #click Autotest Mapping
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_auto_map)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Autotest Mapping'" );
        print FH "STEP: Click the 'Autotest Mapping' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Autotest Mapping' - Pass \n";
    }
    
############################ CLEANUP #############################
    CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_51 { #Change local redirect record
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_51");
    my $sub_name = "ADQ_1411_Auto_MTP3_51";
	my $tcid = "ADQ_1411_Auto_MTP3_51";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    #add NA
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add a PC mapping
    unless(grep/:ADD-PCMAP:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-PCMAP::50-Autotest_mapping:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Add Local Redirect Record 
    unless(grep/:ADD-LOCALREDREC:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LOCALREDREC::50-Autotest_mapping-002.002.002-FCM:CTAG:::::NEWDPC=003.003.003,MOD=Duplicate;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add Local Redirect Record by command 'ADD-LOCALREDREC::50-Autotest_mapping-002.002.002-FCM:CTAG:::::NEWDPC=003.003.003,MOD=Duplicate;'  " );
        print FH "STEP: Add Local Redirect Record by command 'ADD-LOCALREDREC::50-Autotest_mapping-002.002.002-FCM:CTAG:::::NEWDPC=003.003.003,MOD=Duplicate;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add Local Redirect Record by command 'ADD-LOCALREDREC::50-Autotest_mapping-002.002.002-FCM:CTAG:::::NEWDPC=003.003.003,MOD=Duplicate;' - PASS \n";  
    }
    #Change local redirect record
    unless(grep/:CHG-LOCALREDREC:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-LOCALREDREC::50-Autotest_mapping-002.002.002-FCM:CTAG:::::DPC=020.020.020,MSGCAT=TFC,NEWDPC=030.030.030,MOD=Duplicate;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change Local Redirect Record by command 'CHG-LOCALREDREC::50-Autotest_mapping-002.002.002-FCM:CTAG:::::DPC=020.020.020,MSGCAT=TFC,NEWDPC=030.030.030,MOD=Duplicate;'  " );
        print FH "STEP: Change Local Redirect Record by command 'CHG-LOCALREDREC::50-Autotest_mapping-002.002.002-FCM:CTAG:::::DPC=020.020.020,MSGCAT=TFC,NEWDPC=030.030.030,MOD=Duplicate;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change Local Redirect Record by command 'CHG-LOCALREDREC::50-Autotest_mapping-002.002.002-FCM:CTAG:::::DPC=020.020.020,MSGCAT=TFC,NEWDPC=030.030.030,MOD=Duplicate;' - PASS \n";  
    }

    ## Go to url 
    my ($sessionId, $localUrl);
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";  
    my $na50 = "//a[contains(text(),'NA 50')]";
    my $xpath_pc_mapping ="//span[contains (text(),'PC Mappings')]";
    my $xpath_auto_map = "//a[text()='Autotest_mapping']";
    my $xpath_pc_mapping_record = "//a[text()='ANY']";

    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #click PC Mappings tab
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_pc_mapping)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'PC Mappings'" );
        print FH "STEP: Click the 'PC Mappings' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'PC Mappings' - Pass \n";
    }
    #click Autotest Mapping
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_auto_map)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Autotest Mapping'" );
        print FH "STEP: Click the 'Autotest Mapping' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Autotest Mapping' - Pass \n";
    }
    
############################ CLEANUP #############################
    CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_52 { #Verify local redirect record
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_52");
    my $sub_name = "ADQ_1411_Auto_MTP3_52";
	my $tcid = "ADQ_1411_Auto_MTP3_52";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    #add NA
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add a PC mapping
    unless(grep/:ADD-PCMAP:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-PCMAP::50-Autotest_mapping:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Add Local Redirect Record 
    unless(grep/:ADD-LOCALREDREC:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LOCALREDREC::50-Autotest_mapping-002.002.002-FCM:CTAG:::::NEWDPC=003.003.003,MOD=Duplicate;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add Local Redirect Record by command 'ADD-LOCALREDREC::50-Autotest_mapping-002.002.002-FCM:CTAG:::::NEWDPC=003.003.003,MOD=Duplicate;'  " );
        print FH "STEP: Add Local Redirect Record by command 'ADD-LOCALREDREC::50-Autotest_mapping-002.002.002-FCM:CTAG:::::NEWDPC=003.003.003,MOD=Duplicate;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add Local Redirect Record by command 'ADD-LOCALREDREC::50-Autotest_mapping-002.002.002-FCM:CTAG:::::NEWDPC=003.003.003,MOD=Duplicate;' - PASS \n";  
    }
    #Verify local redirect record
    unless(grep/:VFY-LOCALREDREC:CTAG:COMPLD/,$ses_CLI1->execCmd("VFY-LOCALREDREC::50-Autotest_mapping-002.002.002-FCM:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify Local Redirect Record by command 'VFY-LOCALREDREC::50-Autotest_mapping-002.002.002-FCM:CTAG;'  " );
        print FH "STEP: Verify Local Redirect Record by command 'VFY-LOCALREDREC::50-Autotest_mapping-002.002.002-FCM:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Verify Local Redirect Record by command 'VFY-LOCALREDREC::50-Autotest_mapping-002.002.002-FCM:CTAG;' - PASS \n";  
    }

    ## Go to url 
    my ($sessionId, $localUrl);
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";  
    my $na50 = "//a[contains(text(),'NA 50')]";
    my $xpath_pc_mapping ="//span[contains (text(),'PC Mappings')]";
    my $xpath_auto_map = "//a[text()='Autotest_mapping']";
    my $xpath_pc_mapping_record = "//a[text()='ANY']";
    #verify
    my $vrf_dpc_local = "//a[text()='002.002.002']";
    my $vrf_mess_category_local = "//td[text()='FCM']";
    my $vrf_new_dpc_local = "//td[text()='003.003.003']";
    my $vrf_modifier_local = "//td[text()='Duplicate 1000 alternate']";
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #click PC Mappings tab
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_pc_mapping)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'PC Mappings'" );
        print FH "STEP: Click the 'PC Mappings' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'PC Mappings' - Pass \n";
    }
    #click Autotest Mapping
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_auto_map)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Autotest Mapping'" );
        print FH "STEP: Click the 'Autotest Mapping' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Autotest Mapping' - Pass \n";
    }
    #verify
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_dpc_local)) {
        $logger->error(__PACKAGE__ . ".$tcid: Faild to Verify the DPC" );
        print FH "STEP: Verify the DPC - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the DPC - Pass \n";
    }
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_mess_category_local)) {
        $logger->error(__PACKAGE__ . ".$tcid: Faild to Verify the Message Category" );
        print FH "STEP: Verify the Message Category - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the Message Category - Pass \n";
    }
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_new_dpc_local)) {
        $logger->error(__PACKAGE__ . ".$tcid: Faild to Verify the New DPC" );
        print FH "STEP: Verify the New DPC - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the New DPC - Pass \n";
    }
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_modifier_local)) {
        $logger->error(__PACKAGE__ . ".$tcid: Faild to Verify the Modifier" );
        print FH "STEP: Verify the Modifier - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the Modifier - Pass \n";
    }
    
############################ CLEANUP #############################
    CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_53 { #Delete local redirect record
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_53");
    my $sub_name = "ADQ_1411_Auto_MTP3_53";
	my $tcid = "ADQ_1411_Auto_MTP3_53";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    #add NA
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add a PC mapping
    unless(grep/:ADD-PCMAP:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-PCMAP::50-Autotest_mapping:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add PC mapping by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Add Local Redirect Record 
    unless(grep/:ADD-LOCALREDREC:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LOCALREDREC::50-Autotest_mapping-002.002.002-FCM:CTAG:::::NEWDPC=003.003.003,MOD=Duplicate;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add Local Redirect Record by command 'ADD-LOCALREDREC::50-Autotest_mapping-002.002.002-FCM:CTAG:::::NEWDPC=003.003.003,MOD=Duplicate;'  " );
        print FH "STEP: Add Local Redirect Record by command 'ADD-LOCALREDREC::50-Autotest_mapping-002.002.002-FCM:CTAG:::::NEWDPC=003.003.003,MOD=Duplicate;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add Local Redirect Record by command 'ADD-LOCALREDREC::50-Autotest_mapping-002.002.002-FCM:CTAG:::::NEWDPC=003.003.003,MOD=Duplicate;' - PASS \n";  
    }
    
    ## Go to url 
    my ($sessionId, $localUrl);
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";  
    my $na50 = "//a[contains(text(),'NA 50')]";
    my $xpath_pc_mapping ="//span[contains (text(),'PC Mappings')]";
    my $xpath_auto_map = "//a[text()='Autotest_mapping']";
    my $xpath_pc_mapping_record = "//a[text()='ANY']";
  
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    #click PC Mappings tab
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_pc_mapping)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'PC Mappings'" );
        print FH "STEP: Click the 'PC Mappings' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'PC Mappings' - Pass \n";
    }
    #click Autotest Mapping
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_auto_map)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Autotest Mapping'" );
        print FH "STEP: Click the 'Autotest Mapping' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Autotest Mapping' - Pass \n";
    }
    #Delete local redirect record
    unless(grep/:DLT-LOCALREDREC:CTAG:COMPLD;/,$ses_CLI1->execCmd("DLT-LOCALREDREC::50-Autotest_mapping-002.002.002-FCM:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Delete Local Redirect Record by command 'DLT-LOCALREDREC::50-Autotest_mapping-002.002.002-FCM:CTAG;'  " );
        print FH "STEP: Delete Local Redirect Record by command 'DLT-LOCALREDREC::50-Autotest_mapping-002.002.002-FCM:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Delete Local Redirect Record by command 'DLT-LOCALREDREC::50-Autotest_mapping-002.002.002-FCM:CTAG;' - PASS \n";  
    }
############################ CLEANUP #############################
    CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}
sub ADQ_1411_Auto_MTP3_54 { #Verify Link Load Monitoring 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_54");
    my $sub_name = "ADQ_1411_Auto_MTP3_54";
	my $tcid = "ADQ_1411_Auto_MTP3_54";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    
    #---click Linksets
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
    my $xpath_ls = "//input[\@value= 'M2PA Link']/ancestor::div//input[\@title='Create M2PA Link']";
    my $xpath_ls_2 = "//a[text() = 'LS 051.051.051' ]";
    my $create_m2pa = "//input[\@value= 'M2PA Link']/ancestor::div//input[\@title= 'Create M2PA Link']";
    my $slc = "//div[contains (text(), 'SLC')]/ancestor::div[1]//input[\@value]";
    my $value_slc = 0;
    my $dre_id = "//div[contains (text(), 'DRE ID')]/ancestor::div[1]//input[\@value]";
    my $value_dre_id = 1;
    my $create_m2pa_2 = "//input[\@value='Create']";
    my $link_load_monitoring = "//span[text() = 'Link Load Monitoring']";
    #verify
    my $vrf_monitoring = "//div[text() = 'Monitoring']/ancestor::div//span[text() = 'DISABLED']";
    my $vrf_slc_00_Rx = "//div[text() = 'SLC 00 Rx']/ancestor::div[1]//span[text() = '0 %']";
    my $vrf_slc_00_Tx = "//div[text() = 'SLC 00 Tx']/ancestor::div[1]//span[text() = '0 %']";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets'" );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }
    #click LS 051.051.051
    
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets 051.051.051'" );
        print FH "STEP: Click the ' Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets 051.051.051' - Pass \n";
    }
    
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $create_m2pa)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Create'" );
        print FH "STEP: Click the ' Create' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Create' - Pass \n";
    }
    #input value M2PA
    unless ($ses_Selenium->inputText(-xPath => $slc, -text => $value_slc)) {
        $logger->error(__PACKAGE__ . ": Failed to send username '$value_slc' to SLC textbox" );
        print FH "STEP: Input value of SLC '$value_slc' - FAIL \n";
        return 0;
    } else {
        print FH "STEP: Input value of SLC '$value_slc' - PASS \n";
    }
    unless ($ses_Selenium->inputText(-xPath => $dre_id, -text => $value_dre_id)) {
        $logger->error(__PACKAGE__ . ": Failed to send DRE_ID '$value_slc' to DRE_ID textbox" );
        print FH "STEP: Input value of DRE_ID '$value_dre_id' - FAIL \n";
        return 0;
    } else {
        print FH "STEP: Input value of DRE_ID '$value_dre_id' - PASS \n";
    }
    #click create
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $create_m2pa_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Create'" );
        print FH "STEP: Click the ' Create' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Create' - Pass \n";
    }
    #click Link Load Monitoring
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $link_load_monitoring)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Link Load Monitoring'" );
        print FH "STEP: Click the 'Link Load Monitoring' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Link Load Monitoring' - Pass \n";
    }
    #Verify Link Load Monitoring
    my @outputCmd;
    unless(grep/:VFY-LLMON:CTAG:COMPLD/,@outputCmd = $ses_CLI1->execCmd("VFY-LLMON::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify Link Load Monitoring by command 'VFY-LLMON::50-51.51.51:CTAG;'  " );
        print FH "STEP: Verify Link Load Monitoring by command 'VFY-LLMON::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Verify Link Load Monitoring by command 'VFY-LLMON::50-51.51.51:CTAG;' - PASS \n";  
    }
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_monitoring)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the Monitoring" );
        print FH "STEP: Verify the Monitoring - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the Monitoring - Pass \n";
    }
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_slc_00_Rx)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the SLC 00 Rx" );
        print FH "STEP: Verify the SLC 00 Rx - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the SLC 00 Rx - Pass \n";
    }
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_slc_00_Tx)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the SLC 00 Tx" );
        print FH "STEP: Verify the SLC 00 Tx - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the SLC 00 Tx - Pass \n";
    }
  
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_55 { #Add low speed link 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_55");
    my $sub_name = "ADQ_1411_Auto_MTP3_55";
	my $tcid = "ADQ_1411_Auto_MTP3_55";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:2:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Add low speed link
    unless(grep/:ADD-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-SLK::50-51.51.51-5:CTAG::::LS;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LOW SPEED LINK by command 'ADD-SLK::50-51.51.51-5:CTAG::::LS;'  " );
        print FH "STEP: Add LOW SPEED LINK by command 'ADD-SLK::50-51.51.51-5:CTAG::::LS;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LOW SPEED LINK by command 'ADD-SLK::50-51.51.51-5:CTAG::::LS;;' - PASS \n";  
    }
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url_128)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url_128" );
        print FH "STEP: Launch the url '$url_128' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url_128' - PASS \n";
    }
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    
    #---click Linksets
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
    my $xpath_ls_2 = "//a[text() = 'LS 051.051.051' ]";

	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets'" );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }
    #click LS 051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets 051.051.051'" );
        print FH "STEP: Click the ' Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets 051.051.051' - Pass \n";
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_56 { #Add low speed link 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_56");
    my $sub_name = "ADQ_1411_Auto_MTP3_56";
	my $tcid = "ADQ_1411_Auto_MTP3_56";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:2:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Add low speed link
    unless(grep/:ADD-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-SLK::50-51.51.51-5:CTAG::::LS;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LOW SPEED LINK by command 'ADD-SLK::50-51.51.51-5:CTAG::::LS;'  " );
        print FH "STEP: Add LOW SPEED LINK by command 'ADD-SLK::50-51.51.51-5:CTAG::::LS;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LOW SPEED LINK by command 'ADD-SLK::50-51.51.51-5:CTAG::::LS;' - PASS \n";  
    }
    #change low speed link
    unless(grep/:CHG-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-SLK::50-51.51.51-5:CTAG::::LS:CAGE=6,CHASSIS_SLOT=6,CHANNEL=5;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change LOW SPEED LINK by command 'CHG-SLK::50-51.51.51-5:CTAG::::LS:CAGE=6,CHASSIS_SLOT=6,CHANNEL=5;'  " );
        print FH "STEP: Change LOW SPEED LINK by command 'CHG-SLK::50-51.51.51-5:CTAG::::LS:CAGE=6,CHASSIS_SLOT=6,CHANNEL=5;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change LOW SPEED LINK by command 'CHG-SLK::50-51.51.51-5:CTAG::::LS:CAGE=6,CHASSIS_SLOT=6,CHANNEL=5;' - PASS \n";  
    }
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url_128)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url_128" );
        print FH "STEP: Launch the url '$url_128' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url_128' - PASS \n";
    }
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    
    #---click Linksets
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
    my $xpath_ls_2 = "//a[text() = 'LS 051.051.051' ]";

	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets'" );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }
    #click LS 051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets 051.051.051'" );
        print FH "STEP: Click the ' Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets 051.051.051' - Pass \n";
    }

############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_57 { #Set LSL
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_57");
    my $sub_name = "ADQ_1411_Auto_MTP3_57";
	my $tcid = "ADQ_1411_Auto_MTP3_57";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:2:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #set NA
    unless(grep/:SET-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("SET-NA::$NA_50:CTAG:::ACT;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Enable NA by command 'SET-NA::$NA_50:CTAG:::ACT;'  " );
        print FH "STEP: Enable NA by command 'SET-NA::$NA_50:CTAG:::ACT;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Enable NA by command 'SET-NA::$NA_50:CTAG:::ACT;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Add low speed link
    unless(grep/:ADD-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-SLK::50-51.51.51-5:CTAG::::LS;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LOW SPEED LINK by command 'ADD-SLK::50-51.51.51-5:CTAG::::LS;'  " );
        print FH "STEP: Add LOW SPEED LINK by command 'ADD-SLK::50-51.51.51-5:CTAG::::LS;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LOW SPEED LINK by command 'ADD-SLK::50-51.51.51-5:CTAG::::LS;' - PASS \n";  
    }
    #set low speed link
    unless(grep/:SET-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd(" SET-SLK::50-51.51.51-5:CTAG:::ACT:LS;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Set LOW SPEED LINK by command ' SET-SLK::50-51.51.51-5:CTAG:::ACT:LS;'  " );
        print FH "STEP: Set LOW SPEED LINK by command 'SET-SLK::50-51.51.51-5:CTAG:::ACT:LS;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Set LOW SPEED LINK by command 'SET-SLK::50-51.51.51-5:CTAG:::ACT:LS;' - PASS \n";  
    }
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url_128)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url_128" );
        print FH "STEP: Launch the url '$url_128' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url_128' - PASS \n";
    }
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    
    #---click Linksets
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
    my $xpath_ls_2 = "//a[text() = 'LS 051.051.051' ]";

	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets'" );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }
    #click LS 051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets 051.051.051'" );
        print FH "STEP: Click the ' Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets 051.051.051' - Pass \n";
    }

    unless(grep/:SET-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd(" SET-SLK::50-51.51.51-5:CTAG:::DEACT:LS;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Set LOW SPEED LINK by command ' SET-SLK::50-51.51.51-5:CTAG:::DEACT:LS;'  " );
        print FH "STEP: Set LOW SPEED LINK by command 'SET-SLK::50-51.51.51-5:CTAG:::DEACT:LS;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Set LOW SPEED LINK by command 'SET-SLK::50-51.51.51-5:CTAG:::DEACT:LS;' - PASS \n";  
    }

############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_58 { #Add low speed link 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_58");
    my $sub_name = "ADQ_1411_Auto_MTP3_58";
	my $tcid = "ADQ_1411_Auto_MTP3_58";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:2:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Add low speed link
    unless(grep/:ADD-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-SLK::50-51.51.51-5:CTAG::::LS;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LOW SPEED LINK by command 'ADD-SLK::50-51.51.51-5:CTAG::::LS;'  " );
        print FH "STEP: Add LOW SPEED LINK by command 'ADD-SLK::50-51.51.51-5:CTAG::::LS;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LOW SPEED LINK by command 'ADD-SLK::50-51.51.51-5:CTAG::::LS;' - PASS \n";  
    }
    #change low speed link
    unless(grep/:CHG-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-SLK::50-51.51.51-5:CTAG::::LS:CAGE=6,CHASSIS_SLOT=6,CHANNEL=5;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change LOW SPEED LINK by command 'CHG-SLK::50-51.51.51-5:CTAG::::LS:CAGE=6,CHASSIS_SLOT=6,CHANNEL=5;'  " );
        print FH "STEP: Change LOW SPEED LINK by command 'CHG-SLK::50-51.51.51-5:CTAG::::LS:CAGE=6,CHASSIS_SLOT=6,CHANNEL=5;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change LOW SPEED LINK by command 'CHG-SLK::50-51.51.51-5:CTAG::::LS:CAGE=6,CHASSIS_SLOT=6,CHANNEL=5;' - PASS \n";  
    }
    #verify
    unless(grep/:VFY-SLK:CTAG:COMPLD/,$ses_CLI1->execCmd("VFY-SLK::50-51.51.51-5:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify LOW SPEED LINK by command 'VFY-SLK::50-51.51.51-5:CTAG;'  " );
        print FH "STEP: Verify LOW SPEED LINK by command 'VFY-SLK::50-51.51.51-5:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Verify LOW SPEED LINK by command 'VFY-SLK::50-51.51.51-5:CTAG;' - PASS \n";  
    }
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url_128)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url_128" );
        print FH "STEP: Launch the url '$url_128' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url_128' - PASS \n";
    }
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    
    #---click Linksets
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
    my $xpath_ls_2 = "//a[text() = 'LS 051.051.051' ]";
    my $xpath_ls_link_selection = "//a[text() = '051.051.051-05']";
    #verify
    my (@vrf_lsl_, $ind);
    $vrf_lsl_[$ind++] = "//div[text() = 'Context']/ancestor::div[1]//span[text() = '051.051.051-05']";
    $vrf_lsl_[$ind++] = "//div[text() = 'APC']/ancestor::div[1]//span[text() = '051.051.051']";
    $vrf_lsl_[$ind++] = "//div[text() = 'Link Name']/ancestor::div[1]//span[text() = '051.051.051-05']";
    $vrf_lsl_[$ind++] = "//div[text() = 'SLC']/ancestor::div[1]//span[text() = '5']";
    $vrf_lsl_[$ind++] = "//div[text() = 'DRE ID']/ancestor::div[1]//span[text()]";
    $vrf_lsl_[$ind++] = "//div[text() = 'Cage']/ancestor::div[1]//input[\@value = '6']";
    $vrf_lsl_[$ind++] = "//div[text() = 'Chassis Slot']/ancestor::div[1]//input[\@value = '6']";
    $vrf_lsl_[$ind++] = "//div[text() = 'Channel']/ancestor::div[1]//input[\@value = '5']";
    $vrf_lsl_[$ind++] = "//div[text() = 'L2 State']/ancestor::div[1]//span[text()= 'NOT_INITIALIZED']";
    $vrf_lsl_[$ind++] = "//div[text() = 'L3 State']/ancestor::div[1]//span[text()= 'DEACTIVATED']";
    $vrf_lsl_[$ind++] = "//div[text() = 'Congestion Level']/ancestor::div[1]//span[text()= 'FALSE']";
    $vrf_lsl_[$ind++] = "//div[text() = 'Rx MSU Count']/ancestor::div[1]//span[text()= '0']";
    $vrf_lsl_[$ind++] = "//div[text() = 'Tx MSU Count']/ancestor::div[1]//span[text()= '0']";
    $vrf_lsl_[$ind++] = "//div[text() = 'Diagnostic Message']/ancestor::div[1]//span[text()= 'DL unavailable: DM_ERROR: Invalid channel']";
    $vrf_lsl_[$ind++] = "//div[text() = 'Alarms']/ancestor::div[1]//option[\@value = 'ENABLED']";
    $vrf_lsl_[$ind++] = "//div[text() = 'User Activated']/ancestor::div[1]//span[text()= 'DISABLED']";
    $vrf_lsl_[$ind++] = "//div[text() = 'L2 Debug Level']/ancestor::div[1]//input[\@value = '0']";

	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Linksets' " );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }
    #click LS 051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Linksets 051.051.051' " );
        print FH "STEP: Click the 'Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Linksets 051.051.051' - Pass \n";
    }
    #click LS Link Selection
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls_link_selection)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'LS Link Selection'" );
        print FH "STEP: Click the 'LS Link Selection' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'LS Link Selection' - Pass \n";
    }
    #verify
    foreach (@vrf_lsl_){
        my ($ind) = $_ =~ /((?<=\/\/div\[text\(\)\s=\s')[A-Za-z\d\s]*)/;
        unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $_)) {
            $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the $ind" );
            print FH "STEP: Verify the $ind - Fail \n";
            $result = 0;
        } else {
            print FH "STEP: Verify the $ind - Pass \n";
        }       
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_59 { #Delete LSL
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_59");
    my $sub_name = "ADQ_1411_Auto_MTP3_59";
	my $tcid = "ADQ_1411_Auto_MTP3_59";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:2:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:2:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    #Add low speed link
    unless(grep/:ADD-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-SLK::50-51.51.51-5:CTAG::::LS;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LOW SPEED LINK by command 'ADD-SLK::50-51.51.51-5:CTAG::::LS;'  " );
        print FH "STEP: Add LOW SPEED LINK by command 'ADD-SLK::50-51.51.51-5:CTAG::::LS;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LOW SPEED LINK by command 'ADD-SLK::50-51.51.51-5:CTAG::::LS;' - PASS \n";  
    }
   
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url_128)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url_128" );
        print FH "STEP: Launch the url '$url_128' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url_128' - PASS \n";
    }
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    
    #---click Linksets
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
    my $xpath_ls_2 = "//a[text() = 'LS 051.051.051' ]";
  
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets'" );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }
    #click LS 051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets 051.051.051'" );
        print FH "STEP: Click the 'Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Linksets 051.051.051' - Pass \n";
    }
    #Delete low speed link
    unless(grep/:DLT-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("DLT-SLK::50-51.51.51-5:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Delete LOW SPEED LINK by command 'DLT-SLK::50-51.51.51-5:CTAG;'  " );
        print FH "STEP: Delete LOW SPEED LINK by command 'DLT-SLK::50-51.51.51-5:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Delete LOW SPEED LINK by command 'DLT-SLK::50-51.51.51-5:CTAG;' - PASS \n";  
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_60 { #Add ATM Link
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_60");
    my $sub_name = "ADQ_1411_Auto_MTP3_60";
	my $tcid = "ADQ_1411_Auto_MTP3_60"; 
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:2:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:2:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }

    #Add ATM Link
    unless(grep/:ADD-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-SLK::50-51.51.51-0:CTAG::::ATM;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add ATM Link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ATM;'" );
        print FH "STEP: Add ATM Link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ATM;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add ATM Link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ATM;' - PASS \n";  
    }
   
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url_128)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url_128" );
        print FH "STEP: Launch the url '$url_128' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url_128' - PASS \n";
    }
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    
    #---click Linksets
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
    my $xpath_ls_2 = "//a[text() = 'LS 051.051.051' ]";
    my $xpath_atm_link = "//a[text() = '051.051.051-00']";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets'" );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }
    #click LS 051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets 051.051.051'" );
        print FH "STEP: Click the 'Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Linksets 051.051.051' - Pass \n";
    }
    #click ATM Link
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_atm_link)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'ATM Link Selection'" );
        print FH "STEP: Click the 'ATM Link Selection' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'ATM Link Selection' - Pass \n";
    }

############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_61 { #Change ATM Link
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_61");
    my $sub_name = "ADQ_1411_Auto_MTP3_61";
	my $tcid = "ADQ_1411_Auto_MTP3_61";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:2:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:2:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }

    #Add ATM Link
    unless(grep/:ADD-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-SLK::50-51.51.51-0:CTAG::::ATM;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add ATM Link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ATM;'" );
        print FH "STEP: Add ATM Link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ATM;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add ATM Link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ATM;' - PASS \n";  
    }
    #change ATM Link
    unless(grep/:CHG-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-SLK::50-51.51.51-0:CTAG::::ATM:CAGE=6,CHANNEL=6;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change ATM Link by command 'CHG-SLK::50-51.51.51-0:CTAG::::ATM:CAGE=6,CHANNEL=6;'" );
        print FH "STEP: Change ATM Link by command 'CHG-SLK::50-51.51.51-0:CTAG::::ATM:CAGE=6,CHANNEL=6;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change ATM Link by command 'CHG-SLK::50-51.51.51-0:CTAG::::ATM:CAGE=6,CHANNEL=6;' - PASS \n";  
    }
   
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url_128)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url_128" );
        print FH "STEP: Launch the url '$url_128' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url_128' - PASS \n";
    }
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    
    #---click Linksets
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
    my $xpath_ls_2 = "//a[text() = 'LS 051.051.051' ]";
    my $xpath_atm_link = "//a[text() = '051.051.051-00']";
  
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets'" );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }
    #click LS 051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets 051.051.051'" );
        print FH "STEP: Click the 'Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Linksets 051.051.051' - Pass \n";
    }
    #click ATM Link
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_atm_link)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'ATM Link Selection'" );
        print FH "STEP: Click the 'ATM Link Selection' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'ATM Link Selection' - Pass \n";
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_62 { #Set ATM link
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_62");
    my $sub_name = "ADQ_1411_Auto_MTP3_62";
	my $tcid = "ADQ_1411_Auto_MTP3_62";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:2:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:2:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    unless(grep/:SET-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("SET-NA::$NA_50:CTAG:::ACT;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Enable NA by command 'SET-NA::$NA_50:CTAG:::ACT;'  " );
        print FH "STEP: Enable NA by command 'SET-NA::$NA_50:CTAG:::ACT;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Enable NA by command 'SET-NA::$NA_50:CTAG:::ACT;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }

    #Add ATM Link
    unless(grep/:ADD-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-SLK::50-51.51.51-0:CTAG::::ATM;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add ATM Link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ATM;'" );
        print FH "STEP: Add ATM Link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ATM;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add ATM Link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ATM;' - PASS \n";  
    }
    #Set ATM Link
    unless(grep/:SET-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("SET-SLK::50-51.51.51-0:CTAG:::ACT:ATM;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Set ATM Link by command 'SET-SLK::50-51.51.51-0:CTAG:::ACT:ATM;'" );
        print FH "STEP: Set ATM Link by command 'SET-SLK::50-51.51.51-0:CTAG:::ACT:ATM;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Set ATM Link by command 'SET-SLK::50-51.51.51-0:CTAG:::ACT:ATM;' - PASS \n";  
    }

   
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url_128)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url_128" );
        print FH "STEP: Launch the url '$url_128' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url_128' - PASS \n";
    }
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    
    #---click Linksets
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
    my $xpath_ls_2 = "//a[text() = 'LS 051.051.051' ]";
    my $xpath_atm_link = "//a[text() = '051.051.051-00']";
  
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets'" );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }
    #click LS 051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets 051.051.051'" );
        print FH "STEP: Click the 'Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Linksets 051.051.051' - Pass \n";
    }
    #click ATM Link
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_atm_link)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'ATM Link Selection'" );
        print FH "STEP: Click the 'ATM Link Selection' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'ATM Link Selection' - Pass \n";
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}


sub ADQ_1411_Auto_MTP3_63 { #Verify ATM Link
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_63");
    my $sub_name = "ADQ_1411_Auto_MTP3_63";
	my $tcid = "ADQ_1411_Auto_MTP3_63";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:2:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:2:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }

    #Add ATM Link
    unless(grep/:ADD-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-SLK::50-51.51.51-0:CTAG::::ATM;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add ATM Link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ATM;'" );
        print FH "STEP: Add ATM Link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ATM;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add ATM Link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ATM;' - PASS \n";  
    }
    #change ATM Link
    unless(grep/:CHG-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-SLK::50-51.51.51-0:CTAG::::ATM:CAGE=6,CHANNEL=6;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change ATM Link by command 'CHG-SLK::50-51.51.51-0:CTAG::::ATM:CAGE=6,CHANNEL=6;'" );
        print FH "STEP: Change ATM Link by command 'CHG-SLK::50-51.51.51-0:CTAG::::ATM:CAGE=6,CHANNEL=6;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change ATM Link by command 'CHG-SLK::50-51.51.51-0:CTAG::::ATM:CAGE=6,CHANNEL=6;' - PASS \n";  
    }
    #verify ATM Link
    unless(grep/:VFY-SLK-ATM:CTAG:COMPLD/,$ses_CLI1->execCmd(" VFY-SLK-ATM::50-51.51.51-0:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify ATM Link by command ' VFY-SLK-ATM::50-51.51.51-0:CTAG;'" );
        print FH "STEP: Verify ATM Link by command 'VFY-SLK-ATM::50-51.51.51-0:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Verify ATM Link by command 'VFY-SLK-ATM::50-51.51.51-0:CTAG;' - PASS \n";  
    }
   
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url_128)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url_128" );
        print FH "STEP: Launch the url '$url_128' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url_128' - PASS \n";
    }
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    
    #---click Linksets
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
    my $xpath_ls_2 = "//a[text() = 'LS 051.051.051' ]";
    my $xpath_atm_link = "//a[text() = '051.051.051-00']";
    #verify
    my (@vrf_atm_link_ , $ind_);
    $vrf_atm_link_[$ind_++] = "//div[text()='Context']/ancestor::div[1]//span[text()='051.051.051-00']";
    $vrf_atm_link_[$ind_++] = "//div[text()='APC']/ancestor::div[1]//span[text()='051.051.051']";
    $vrf_atm_link_[$ind_++] = "//div[text()='Link Name']/ancestor::div[1]//span[text()='051.051.051-00']";
    $vrf_atm_link_[$ind_++] = "//div[text()='SLC']/ancestor::div[1]//span[text()='0']";
    # $vrf_atm_link_[$ind_++] = "//div[text()='DRE ID']/ancestor::div[1]//span[text()='3']";
    $vrf_atm_link_[$ind_++] = "//div[text()='Cage']/ancestor::div[1]//input[\@value='6']";
    $vrf_atm_link_[$ind_++] = "//div[text()='Channel']/ancestor::div[1]//input[\@value='6']";
    $vrf_atm_link_[$ind_++] = "//div[text()='L2 State']/ancestor::div[1]//span[text()='NOT_INITIALIZED']";
    $vrf_atm_link_[$ind_++] = "//div[text()='L3 State']/ancestor::div[1]//span[text()='DEACTIVATED']";
    $vrf_atm_link_[$ind_++] = "//div[text()='Congestion Level']/ancestor::div[1]//span[text()='FALSE']";
    $vrf_atm_link_[$ind_++] = "//div[text()='Rx MSU Count']/ancestor::div[1]//span[text()='0']";
    $vrf_atm_link_[$ind_++] = "//div[text()='Tx MSU Count']/ancestor::div[1]//span[text()='0']";
    $vrf_atm_link_[$ind_++] = "//div[text()='Diagnostic Message']/ancestor::div[1]//span[text()='DL unavailable: DM_ERROR: Invalid channel']";
    $vrf_atm_link_[$ind_++] = "//div[text()='Alarms']/ancestor::div[1]//option[\@value='ENABLED']";
    $vrf_atm_link_[$ind_++] = "//div[text()='User Activated']/ancestor::div[1]//span[text()='DISABLED']";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets'" );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }
    #click LS 051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets 051.051.051'" );
        print FH "STEP: Click the 'Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Linksets 051.051.051' - Pass \n";
    }
    #click ATM Link
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_atm_link)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'ATM Link Selection'" );
        print FH "STEP: Click the 'ATM Link Selection' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'ATM Link Selection' - Pass \n";
    }
    #verify
    foreach(@vrf_atm_link_){
        my ($ind_) = $_ =~ /((?<=\/\/div\[text\(\)=')[A-Za-z\d\s]*(?='\]))/;
        unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $_)) {
            $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the $ind_" );
            print FH "STEP: Verify the $ind_ - Fail \n";
            $result = 0;
        } else {
            print FH "STEP: Verify the $ind_ - Pass \n";
        }      
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_64 { #Delete ATM Link
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_64");
    my $sub_name = "ADQ_1411_Auto_MTP3_64";
	my $tcid = "ADQ_1411_Auto_MTP3_64";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:2:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:2:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }

    #Add ATM Link
    unless(grep/:ADD-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-SLK::50-51.51.51-0:CTAG::::ATM;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add ATM Link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ATM;'" );
        print FH "STEP: Add ATM Link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ATM;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add ATM Link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ATM;' - PASS \n";  
    }
   
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url_128)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url_128" );
        print FH "STEP: Launch the url '$url_128' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url_128' - PASS \n";
    }
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    
    #---click Linksets
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
    my $xpath_ls_2 = "//a[text() = 'LS 051.051.051' ]";
    my $xpath_atm_link = "//a[text() = '051.051.051-00']";
   
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets'" );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }
    #click LS 051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets 051.051.051'" );
        print FH "STEP: Click the 'Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Linksets 051.051.051' - Pass \n";
    }
    #click ATM Link
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_atm_link)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'ATM Link Selection'" );
        print FH "STEP: Click the 'ATM Link Selection' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'ATM Link Selection' - Pass \n";
    }
    #Delete ATM Link
    unless(grep/:DLT-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("DLT-SLK::50-51.51.51-0:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Delete ATM Link by command 'DLT-SLK::50-51.51.51-0:CTAG;'" );
        print FH "STEP: Delete ATM Link by command 'DLT-SLK::50-51.51.51-0:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Delete ATM Link by command 'DLT-SLK::50-51.51.51-0:CTAG;' - PASS \n";  
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_65 { #Add Annex A link
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_65");
    my $sub_name = "ADQ_1411_Auto_MTP3_65";
	my $tcid = "ADQ_1411_Auto_MTP3_65";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:2:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:2:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }

    #Add Annex A link
    unless(grep/:ADD-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-SLK::50-51.51.51-0:CTAG::::ANNEXA;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add Annex A link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ANNEXA;'" );
        print FH "STEP: Add Annex A link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ANNEXA;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add Annex A link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ANNEXA;' - PASS \n";  
    }
   
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url_128)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url_128" );
        print FH "STEP: Launch the url '$url_128' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url_128' - PASS \n";
    }
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    
    #---click Linksets
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
    my $xpath_ls_2 = "//a[text() = 'LS 051.051.051' ]";
    
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets'" );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }
    #click LS 051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets 051.051.051'" );
        print FH "STEP: Click the 'Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Linksets 051.051.051' - Pass \n";
    }

############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_66 { #Change Annex A link
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_66");
    my $sub_name = "ADQ_1411_Auto_MTP3_66";
	my $tcid = "ADQ_1411_Auto_MTP3_66";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:2:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:2:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }

    #Add Annex A link
    unless(grep/:ADD-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-SLK::50-51.51.51-0:CTAG::::ANNEXA;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add Annex A link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ANNEXA;'" );
        print FH "STEP: Add Annex A link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ANNEXA;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add Annex A link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ANNEXA;' - PASS \n";  
    }
    #Change Annex A link
    unless(grep/:CHG-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-SLK::50-51.51.51-0:CTAG::::ANNEXA:CAGE=6,CHASSIS_SLOT=6,CHANNEL=6;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change Annex A link by command 'CHG-SLK::50-51.51.51-0:CTAG::::ANNEXA:CAGE=6,CHASSIS_SLOT=6,CHANNEL=6;'" );
        print FH "STEP: Change Annex A link by command 'CHG-SLK::50-51.51.51-0:CTAG::::ANNEXA:CAGE=6,CHASSIS_SLOT=6,CHANNEL=6;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change Annex A link by command 'CHG-SLK::50-51.51.51-0:CTAG::::ANNEXA:CAGE=6,CHASSIS_SLOT=6,CHANNEL=6;' - PASS \n";  
    }

   
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url_128)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url_128" );
        print FH "STEP: Launch the url '$url_128' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url_128' - PASS \n";
    }
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    
    #---click Linksets
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
    my $xpath_ls_2 = "//a[text() = 'LS 051.051.051' ]";
    my $xpath_annex_link = "//a[text() = '051.051.051-00' ]";
    
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets'" );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }
    #click LS 051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets 051.051.051'" );
        print FH "STEP: Click the 'Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Linksets 051.051.051' - Pass \n";
    }
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_annex_link)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets 051.051.051'" );
        print FH "STEP: Click the 'Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Linksets 051.051.051' - Pass \n";
    }


    

############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_67 { #Set Annex A link
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_67");
    my $sub_name = "ADQ_1411_Auto_MTP3_67";
	my $tcid = "ADQ_1411_Auto_MTP3_67";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:2:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:2:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    unless(grep/:SET-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("SET-NA::$NA_50:CTAG:::ACT;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Enable NA by command 'SET-NA::$NA_50:CTAG:::ACT;'  " );
        print FH "STEP: Enable NA by command 'SET-NA::$NA_50:CTAG:::ACT;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Enable NA by command 'SET-NA::$NA_50:CTAG:::ACT;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }

    #Add Annex A link
    unless(grep/:ADD-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-SLK::50-51.51.51-0:CTAG::::ANNEXA;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add Annex A link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ANNEXA;'" );
        print FH "STEP: Add Annex A link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ANNEXA;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add Annex A link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ANNEXA;' - PASS \n";  
    }
    #Set Annex A link
    unless(grep/:SET-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("SET-SLK::50-51.51.51-0:CTAG:::ACT:ANNEXA;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Set Annex A link by command 'SET-SLK::50-51.51.51-0:CTAG:::ACT:ANNEXA;'" );
        print FH "STEP: Set Annex A link by command 'SET-SLK::50-51.51.51-0:CTAG:::ACT:ANNEXA;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Set Annex A link by command 'SET-SLK::50-51.51.51-0:CTAG:::ACT:ANNEXA;' - PASS \n";  
    }

   
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url_128)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url_128" );
        print FH "STEP: Launch the url '$url_128' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url_128' - PASS \n";
    }
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    
    #---click Linksets
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
    my $xpath_ls_2 = "//a[text() = 'LS 051.051.051' ]";
    
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets'" );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }
    #click LS 051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets 051.051.051'" );
        print FH "STEP: Click the 'Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Linksets 051.051.051' - Pass \n";
    }

    #Set Annex A link
    unless(grep/:SET-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("SET-SLK::50-51.51.51-0:CTAG:::DEACT:ANNEXA;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Set Annex A link by command 'SET-SLK::50-51.51.51-0:CTAG:::DEACT:ANNEXA;'" );
        print FH "STEP: Set Annex A link by command 'SET-SLK::50-51.51.51-0:CTAG:::DEACT:ANNEXA;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Set Annex A link by command 'SET-SLK::50-51.51.51-0:CTAG:::DEACT:ANNEXA;' - PASS \n";  
    }
 
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_68 { #Verify Annex A link
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_68");
    my $sub_name = "ADQ_1411_Auto_MTP3_68";
	my $tcid = "ADQ_1411_Auto_MTP3_68";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:2:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:2:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }

    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }

    #Add Annex A link
    unless(grep/:ADD-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-SLK::50-51.51.51-0:CTAG::::ANNEXA;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add Annex A link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ANNEXA;'" );
        print FH "STEP: Add Annex A link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ANNEXA;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add Annex A link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ANNEXA;' - PASS \n";  
    }
    #Change Annex A link
    unless(grep/:CHG-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-SLK::50-51.51.51-0:CTAG::::ANNEXA:CAGE=6,CHASSIS_SLOT=6,CHANNEL=6;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change Annex A link by command 'CHG-SLK::50-51.51.51-0:CTAG::::ANNEXA:CAGE=6,CHASSIS_SLOT=6,CHANNEL=6;'" );
        print FH "STEP: Change Annex A link by command 'CHG-SLK::50-51.51.51-0:CTAG::::ANNEXA:CAGE=6,CHASSIS_SLOT=6,CHANNEL=6;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change Annex A link by command 'CHG-SLK::50-51.51.51-0:CTAG::::ANNEXA:CAGE=6,CHASSIS_SLOT=6,CHANNEL=6;' - PASS \n";  
    }
    #verify Annex A Link
    unless(grep/:VFY-SLK:CTAG:COMPLD/,$ses_CLI1->execCmd("VFY-SLK::50-51.51.51-0:CTAG::::ANNEXA;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify Annex A link by command 'VFY-SLK::50-51.51.51-0:CTAG::::ANNEXA;'" );
        print FH "STEP: Verify Annex A link by command 'VFY-SLK::50-51.51.51-0:CTAG::::ANNEXA;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Verify Annex A link by command 'VFY-SLK::50-51.51.51-0:CTAG::::ANNEXA;' - PASS \n";  
    }

   
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url_128)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url_128" );
        print FH "STEP: Launch the url '$url_128' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url_128' - PASS \n";
    }
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    
    #---click Linksets
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
    my $xpath_ls_2 = "//a[text() = 'LS 051.051.051' ]";
    my $xpath_annex_link = "//a[text()='051.051.051-00']";
    #verify
    my (@vrf_ , $ind_);
    $vrf_[$ind_++] = "//div[text()='Context']/ancestor::div[1]//span[text()='051.051.051-00']";
    $vrf_[$ind_++] = "//div[text()='APC']/ancestor::div[1]//span[text()='051.051.051']";
    $vrf_[$ind_++] = "//div[text()='Link Name']/ancestor::div[1]//span[text()='051.051.051-00']";
    $vrf_[$ind_++] = "//div[text()='SLC']/ancestor::div[1]//span[text()='0']";
    $vrf_[$ind_++] = "//div[text()='DRE ID']/ancestor::div[1]//span[text()='3']";
    $vrf_[$ind_++] = "//div[text()='Cage']/ancestor::div[1]//input[\@value='6']";
    $vrf_[$ind_++] = "//div[text()='Channel']/ancestor::div[1]//input[\@value='6']";
    $vrf_[$ind_++] = "//div[text()='L2 State']/ancestor::div[1]//span[text()='NOT_INITIALIZED']";
    $vrf_[$ind_++] = "//div[text()='L3 State']/ancestor::div[1]//span[text()='DEACTIVATED']";
    $vrf_[$ind_++] = "//div[text()='Congestion Level']/ancestor::div[1]//span[text()='FALSE']";
    $vrf_[$ind_++] = "//div[text()='Rx MSU Count']/ancestor::div[1]//span[text()='0']";
    $vrf_[$ind_++] = "//div[text()='Tx MSU Count']/ancestor::div[1]//span[text()='0']";
    $vrf_[$ind_++] = "//div[text()='Diagnostic Message']/ancestor::div[1]//span[text()='DL unavailable: DM_ERROR: ERR_Unknown']";
    $vrf_[$ind_++] = "//div[text()='Alarms']/ancestor::div[1]//option[\@value='ENABLED']";
    $vrf_[$ind_++] = "//div[text()='User Activated']/ancestor::div[1]//span[text()='DISABLED']";
    
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets'" );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }
    #click LS 051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets 051.051.051'" );
        print FH "STEP: Click the 'Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Linksets 051.051.051' - Pass \n";
    }
    #click Annex A Link Selection
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_annex_link)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Annex A Link Selection 051.051.051'" );
        print FH "STEP: Click the 'Annex A Link Selection 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Annex A Link Selection 051.051.051' - Pass \n";
    }
    #verify
    foreach(@vrf_){
        my ($ind_) = $_ =~ /((?<=\/\/div\[text\(\)=')[A-Za-z\d\s]*(?='\]))/;
        unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $_)) {
            $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the $ind_" );
            print FH "STEP: Verify the $ind_ - Fail \n";
            $result = 0;
        } else {
            print FH "STEP: Verify the $ind_ - Pass \n";
        }      
    }
 
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}


sub ADQ_1411_Auto_MTP3_69 { #Verify Annex A link
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_69");
    my $sub_name = "ADQ_1411_Auto_MTP3_69";
	my $tcid = "ADQ_1411_Auto_MTP3_69";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:2:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:2:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }

    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }

    #Add Annex A link
    unless(grep/:ADD-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-SLK::50-51.51.51-0:CTAG::::ANNEXA;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add Annex A link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ANNEXA;'" );
        print FH "STEP: Add Annex A link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ANNEXA;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add Annex A link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ANNEXA;' - PASS \n";  
    }
    #Change Annex A link
    unless(grep/:CHG-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-SLK::50-51.51.51-0:CTAG::::ANNEXA:CAGE=6,CHASSIS_SLOT=6,CHANNEL=6;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change Annex A link by command 'CHG-SLK::50-51.51.51-0:CTAG::::ANNEXA:CAGE=6,CHASSIS_SLOT=6,CHANNEL=6;'" );
        print FH "STEP: Change Annex A link by command 'CHG-SLK::50-51.51.51-0:CTAG::::ANNEXA:CAGE=6,CHASSIS_SLOT=6,CHANNEL=6;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change Annex A link by command 'CHG-SLK::50-51.51.51-0:CTAG::::ANNEXA:CAGE=6,CHASSIS_SLOT=6,CHANNEL=6;' - PASS \n";  
    }
    #verify Annex A Link
    unless(grep/:VFY-SLK-ANNEXA:CTAG:COMPLD/,$ses_CLI1->execCmd("VFY-SLK-ANNEXA::50-51.51.51-0:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify Annex A link by command 'VFY-SLK-ANNEXA::50-51.51.51-0:CTAG;'" );
        print FH "STEP: Verify Annex A link by command 'VFY-SLK-ANNEXA::50-51.51.51-0:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Verify Annex A link by command 'VFY-SLK-ANNEXA::50-51.51.51-0:CTAG;' - PASS \n";  
    }

   
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url_128)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url_128" );
        print FH "STEP: Launch the url '$url_128' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url_128' - PASS \n";
    }
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    
    #---click Linksets
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
    my $xpath_ls_2 = "//a[text() = 'LS 051.051.051' ]";
    my $xpath_annex_link = "//a[text()='051.051.051-00']";
    #verify
    my (@vrf_ , $ind_);
    $vrf_[$ind_++] = "//div[text()='Context']/ancestor::div[1]//span[text()='051.051.051-00']";
    $vrf_[$ind_++] = "//div[text()='APC']/ancestor::div[1]//span[text()='051.051.051']";
    $vrf_[$ind_++] = "//div[text()='Link Name']/ancestor::div[1]//span[text()='051.051.051-00']";
    $vrf_[$ind_++] = "//div[text()='SLC']/ancestor::div[1]//span[text()='0']";
    # $vrf_[$ind_++] = "//div[text()='DRE ID']/ancestor::div[1]//span[text()='3']";
    $vrf_[$ind_++] = "//div[text()='Cage']/ancestor::div[1]//input[\@value='6']";
    $vrf_[$ind_++] = "//div[text()='Channel']/ancestor::div[1]//input[\@value='6']";
    $vrf_[$ind_++] = "//div[text()='L2 State']/ancestor::div[1]//span[text()='NOT_INITIALIZED']";
    $vrf_[$ind_++] = "//div[text()='L3 State']/ancestor::div[1]//span[text()='DEACTIVATED']";
    $vrf_[$ind_++] = "//div[text()='Congestion Level']/ancestor::div[1]//span[text()='FALSE']";
    $vrf_[$ind_++] = "//div[text()='Rx MSU Count']/ancestor::div[1]//span[text()='0']";
    $vrf_[$ind_++] = "//div[text()='Tx MSU Count']/ancestor::div[1]//span[text()='0']";
    $vrf_[$ind_++] = "//div[text()='Diagnostic Message']/ancestor::div[1]//span[text()='DL unavailable: DM_ERROR: ERR_Unknown']";
    $vrf_[$ind_++] = "//div[text()='Alarms']/ancestor::div[1]//option[\@value='ENABLED']";
    $vrf_[$ind_++] = "//div[text()='User Activated']/ancestor::div[1]//span[text()='DISABLED']";
    
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets'" );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }
    #click LS 051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets 051.051.051'" );
        print FH "STEP: Click the 'Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Linksets 051.051.051' - Pass \n";
    }
    #click Annex A Link Selection
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_annex_link)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Annex A Link Selection 051.051.051'" );
        print FH "STEP: Click the 'Annex A Link Selection 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Annex A Link Selection 051.051.051' - Pass \n";
    }
    #verify
    foreach(@vrf_){
        my ($ind_) = $_ =~ /((?<=\/\/div\[text\(\)=')[A-Za-z\d\s]*(?='\]))/;
        unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $_)) {
            $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the $ind_" );
            print FH "STEP: Verify the $ind_ - Fail \n";
            $result = 0;
        } else {
            print FH "STEP: Verify the $ind_ - Pass \n";
        }      
    }
 
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}


sub ADQ_1411_Auto_MTP3_70 { #Delete Annex A link
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_70");
    my $sub_name = "ADQ_1411_Auto_MTP3_70";
	my $tcid = "ADQ_1411_Auto_MTP3_70";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:2:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:2:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }

    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }

    #Add Annex A link
    unless(grep/:ADD-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-SLK::50-51.51.51-0:CTAG::::ANNEXA;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add Annex A link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ANNEXA;'" );
        print FH "STEP: Add Annex A link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ANNEXA;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add Annex A link by command 'ADD-SLK::50-51.51.51-0:CTAG::::ANNEXA;' - PASS \n";  
    }
   
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url_128)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url_128" );
        print FH "STEP: Launch the url '$url_128' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url_128' - PASS \n";
    }
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    
    #---click Linksets
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
    my $xpath_ls_2 = "//a[text() = 'LS 051.051.051' ]";
    my $xpath_annex_link = "//a[text()='051.051.051-00']";

	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets'" );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }
    #click LS 051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets 051.051.051'" );
        print FH "STEP: Click the 'Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Linksets 051.051.051' - Pass \n";
    }
    #click Annex A Link Selection
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_annex_link)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Annex A Link Selection 051.051.051'" );
        print FH "STEP: Click the 'Annex A Link Selection 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Annex A Link Selection 051.051.051' - Pass \n";
    }
    #Delete Annex A link
    unless(grep/:DLT-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("DLT-SLK::50-51.51.51-0:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Delete Annex A link by command ' DLT-SLK::50-51.51.51-0:CTAG;'" );
        print FH "STEP: Delete Annex A link by command 'DLT-SLK::50-51.51.51-0:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Delete Annex A link by command 'DLT-SLK::50-51.51.51-0:CTAG;' - PASS \n";  
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}


sub ADQ_1411_Auto_MTP3_71 { #Add Generic link
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_71");
    my $sub_name = "ADQ_1411_Auto_MTP3_71";
	my $tcid = "ADQ_1411_Auto_MTP3_71";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:2:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:2:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }

    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }

    #Add Generic link
    unless(grep/:ADD-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-SLK::50-51.51.51-0:CTAG::::GENERIC:LINK_TYPE=M3UA_SG,DRE_ID=3;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add Generic Link by command 'ADD-SLK::50-51.51.51-0:CTAG::::GENERIC:LINK_TYPE=M3UA_SG,DRE_ID=3;'" );
        print FH "STEP: Add Generic link by command 'ADD-SLK::50-51.51.51-0:CTAG::::GENERIC:LINK_TYPE=M3UA_SG,DRE_ID=3;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add Generic link by command 'ADD-SLK::50-51.51.51-0:CTAG::::GENERIC:LINK_TYPE=M3UA_SG,DRE_ID=3;' - PASS \n";  
    }
   
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url_128)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url_128" );
        print FH "STEP: Launch the url '$url_128' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url_128' - PASS \n";
    }
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    
    #---click Linksets
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
    my $xpath_ls_2 = "//a[text() = 'LS 051.051.051' ]";
    my $xpath_generic_link = "//a[text()='051.051.051-00']";

	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets'" );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }
    #click LS 051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets 051.051.051'" );
        print FH "STEP: Click the 'Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Linksets 051.051.051' - Pass \n";
    }
    #click Annex A Link Selection
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_generic_link)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Generic Link Selection 051.051.051'" );
        print FH "STEP: Click the 'Generic Link Selection 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Generic Link Selection 051.051.051' - Pass \n";
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}   

sub ADQ_1411_Auto_MTP3_72 { #Change Generic link
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_72");
    my $sub_name = "ADQ_1411_Auto_MTP3_72";
	my $tcid = "ADQ_1411_Auto_MTP3_72";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:2:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:2:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }

    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }

    #Add Generic link
    unless(grep/:ADD-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-SLK::50-51.51.51-0:CTAG::::GENERIC:LINK_TYPE=M3UA_SG,DRE_ID=3;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add Generic Link by command 'ADD-SLK::50-51.51.51-0:CTAG::::GENERIC:LINK_TYPE=M3UA_SG,DRE_ID=3;'" );
        print FH "STEP: Add Generic link by command 'ADD-SLK::50-51.51.51-0:CTAG::::GENERIC:LINK_TYPE=M3UA_SG,DRE_ID=3;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add Generic link by command 'ADD-SLK::50-51.51.51-0:CTAG::::GENERIC:LINK_TYPE=M3UA_SG,DRE_ID=3;' - PASS \n";  
    }
    #Change Generic link
    unless(grep/:CHG-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-SLK::50-51.51.51-0:CTAG::::GENERIC:LOCAL_IPADDR1=10.91.2.128,LOCAL_PORT=5000,REMOTE_IPADDR1=10.91.2.129,REMOTE_PORT=5001;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change Generic link by command 'CHG-SLK::50-51.51.51-0:CTAG::::GENERIC:LOCAL_IPADDR1=10.91.2.128,LOCAL_PORT=5000,REMOTE_IPADDR1=10.91.2.129,REMOTE_PORT=5001;'  " );
        print FH "STEP: Change Generic link by command 'CHG-SLK::50-51.51.51-0:CTAG::::GENERIC:LOCAL_IPADDR1=10.91.2.128,LOCAL_PORT=5000,REMOTE_IPADDR1=10.91.2.129,REMOTE_PORT=5001;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change Generic linkA by command 'CHG-SLK::50-51.51.51-0:CTAG::::GENERIC:LOCAL_IPADDR1=10.91.2.128,LOCAL_PORT=5000,REMOTE_IPADDR1=10.91.2.129,REMOTE_PORT=5001;' - PASS \n";  
    }
   
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url_128)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url_128" );
        print FH "STEP: Launch the url '$url_128' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url_128' - PASS \n";
    }
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    
    #---click Linksets
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
    my $xpath_ls_2 = "//a[text() = 'LS 051.051.051' ]";
    my $xpath_generic_link = "//a[text()='051.051.051-00']";

	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets'" );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }
    #click LS 051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets 051.051.051'" );
        print FH "STEP: Click the 'Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Linksets 051.051.051' - Pass \n";
    }
    #click Annex A Link Selection
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_generic_link)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Generic Link Selection 051.051.051'" );
        print FH "STEP: Click the 'Generic Link Selection 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Generic Link Selection 051.051.051' - Pass \n";
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
} 



sub ADQ_1411_Auto_MTP3_73 { #Set Generic link
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_73");
    my $sub_name = "ADQ_1411_Auto_MTP3_73";
	my $tcid = "ADQ_1411_Auto_MTP3_73";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:2:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:2:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    unless(grep/:SET-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("SET-NA::$NA_50:CTAG:::ACT;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Enable NA by command 'SET-NA::$NA_50:CTAG:::ACT;'  " );
        print FH "STEP: Enable NA by command 'SET-NA::$NA_50:CTAG:::ACT;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Enable NA by command 'SET-NA::$NA_50:CTAG:::ACT;' - PASS \n";  
    }

    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }

    #Add Generic link
    unless(grep/:ADD-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-SLK::50-51.51.51-0:CTAG::::GENERIC:LINK_TYPE=M3UA_SG,DRE_ID=3;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add Generic Link by command 'ADD-SLK::50-51.51.51-0:CTAG::::GENERIC:LINK_TYPE=M3UA_SG,DRE_ID=3;'" );
        print FH "STEP: Add Generic link by command 'ADD-SLK::50-51.51.51-0:CTAG::::GENERIC:LINK_TYPE=M3UA_SG,DRE_ID=3;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add Generic link by command 'ADD-SLK::50-51.51.51-0:CTAG::::GENERIC:LINK_TYPE=M3UA_SG,DRE_ID=3;' - PASS \n";  
    }
    #Set Generic link
    unless(grep/:SET-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("SET-SLK::50-51.51.51-0:CTAG:::ACT:GENERIC;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Set Generic link by command 'SET-SLK::50-51.51.51-0:CTAG:::ACT:GENERIC;'" );
        print FH "STEP: Set Generic link by command 'SET-SLK::50-51.51.51-0:CTAG:::ACT:GENERIC;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Set Generic link by command 'SET-SLK::50-51.51.51-0:CTAG:::ACT:GENERIC;' - PASS \n";  
    }
   
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url_128)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url_128" );
        print FH "STEP: Launch the url '$url_128' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url_128' - PASS \n";
    }
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    
    #---click Linksets
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
    my $xpath_ls_2 = "//a[text() = 'LS 051.051.051' ]";
    my $xpath_generic_link = "//a[text()='051.051.051-00']";

	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets'" );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }
    #click LS 051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets 051.051.051'" );
        print FH "STEP: Click the 'Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Linksets 051.051.051' - Pass \n";
    }
    #click genneric Link Selection
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_generic_link)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Generic Link Selection 051.051.051'" );
        print FH "STEP: Click the 'Generic Link Selection 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Generic Link Selection 051.051.051' - Pass \n";
    }
    #DEACT Generic link
    unless(grep/:SET-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("SET-SLK::50-51.51.51-0:CTAG:::DEACT:GENERIC;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Set Generic link by command 'SET-SLK::50-51.51.51-0:CTAG:::DEACT:GENERIC;'" );
        print FH "STEP: Set Generic link by command 'SET-SLK::50-51.51.51-0:CTAG:::DEACT:GENERIC;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Set Generic link by command 'SET-SLK::50-51.51.51-0:CTAG:::DEACT:GENERIC;' - PASS \n";  
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
} 

sub ADQ_1411_Auto_MTP3_74 { #Verify Generic link
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_74");
    my $sub_name = "ADQ_1411_Auto_MTP3_74";
	my $tcid = "ADQ_1411_Auto_MTP3_74";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:2:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:2:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }

    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }

    #Add Generic link
    unless(grep/:ADD-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-SLK::50-51.51.51-0:CTAG::::GENERIC:LINK_TYPE=M3UA_SG,DRE_ID=3;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add Generic Link by command 'ADD-SLK::50-51.51.51-0:CTAG::::GENERIC:LINK_TYPE=M3UA_SG,DRE_ID=3;'" );
        print FH "STEP: Add Generic link by command 'ADD-SLK::50-51.51.51-0:CTAG::::GENERIC:LINK_TYPE=M3UA_SG,DRE_ID=3;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add Generic link by command 'ADD-SLK::50-51.51.51-0:CTAG::::GENERIC:LINK_TYPE=M3UA_SG,DRE_ID=3;' - PASS \n";  
    }
    #Change Generic link
    unless(grep/:CHG-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-SLK::50-51.51.51-0:CTAG::::GENERIC:LOCAL_IPADDR1=10.91.2.128,LOCAL_PORT=5000,REMOTE_IPADDR1=10.91.2.129,REMOTE_PORT=5001;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change Generic link by command 'CHG-SLK::50-51.51.51-0:CTAG::::GENERIC:LOCAL_IPADDR1=10.91.2.128,LOCAL_PORT=5000,REMOTE_IPADDR1=10.91.2.129,REMOTE_PORT=5001;'  " );
        print FH "STEP: Change Generic link by command 'CHG-SLK::50-51.51.51-0:CTAG::::GENERIC:LOCAL_IPADDR1=10.91.2.128,LOCAL_PORT=5000,REMOTE_IPADDR1=10.91.2.129,REMOTE_PORT=5001;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change Generic linkA by command 'CHG-SLK::50-51.51.51-0:CTAG::::GENERIC:LOCAL_IPADDR1=10.91.2.128,LOCAL_PORT=5000,REMOTE_IPADDR1=10.91.2.129,REMOTE_PORT=5001;' - PASS \n";  
    }
    #Verify Generic link
    unless(grep/:VFY-SLK-GENERIC:CTAG:COMPLD/,$ses_CLI1->execCmd("VFY-SLK-GENERIC::50-51.51.51-0:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify Generic link by command 'VFY-SLK-GENERIC::50-51.51.51-0:CTAG;'  " );
        print FH "STEP: Verify Generic link by command 'VFY-SLK-GENERIC::50-51.51.51-0:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Verify Generic linkA by command 'VFY-SLK-GENERIC::50-51.51.51-0:CTAG;' - PASS \n";  
    }
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url_128)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url_128" );
        print FH "STEP: Launch the url '$url_128' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url_128' - PASS \n";
    }
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    
    #---click Linksets
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
    my $xpath_ls_2 = "//a[text() = 'LS 051.051.051' ]";
    my $xpath_generic_link = "//a[text()='051.051.051-00']";
    #verify
    my (@vrf__, $ind_);
    $vrf__[$ind_++] = "//div[text()='Context']/ancestor::div//span[text()='051.051.051-00']";
    $vrf__[$ind_++] = "//div[text()='SLC']/ancestor::div[1]//span[text()='0']";
    $vrf__[$ind_++] = "//div[text()='Link Type']/ancestor::div[1]//span[text()='M3UA_SG']";
    $vrf__[$ind_++] = "//div[text()='DRE ID']/ancestor::div//span[text()='3']";
    $vrf__[$ind_++] = "//div[text()='Local IP Address 1']/ancestor::div//input[\@value='10.91.2.128']";
    $vrf__[$ind_++] = "//div[text()='Local IP Address 2']/ancestor::div[1]//input";
    $vrf__[$ind_++] = "//div[text()='Local Port']/ancestor::div[1]//input[\@value='5000']";
    $vrf__[$ind_++] = "//div[text()='Remote IP Address 1']/ancestor::div//input[\@value='10.91.2.129']";
    $vrf__[$ind_++] = "//div[text()='Remote IP Address 2']/ancestor::div[1]//input";
    $vrf__[$ind_++] = "//div[text()='Remote Port']/ancestor::div//input[\@value='5001']";
    $vrf__[$ind_++] = "//div[text()='L2 State']/ancestor::div//span[text()='OUT_OF_SERVICE']";
    $vrf__[$ind_++] = "//div[text()='L3 State']/ancestor::div//span[text()='DEACTIVATED']";
    $vrf__[$ind_++] = "//div[text()='Rx MSU Count']/ancestor::div[1]//span[text()='0']";
    $vrf__[$ind_++] = "//div[text()='Tx MSU Count']/ancestor::div[1]//span[text()='0']";
    $vrf__[$ind_++] = "//div[text()='Diagnostic Message']/ancestor::div//span[text()='Configured']";
    $vrf__[$ind_++] = "//div[text()='DataLink Bandwidth']/ancestor::div//input[\@value='64']";
    $vrf__[$ind_++] = "//div[text()='Alarms']/ancestor::div//input[\@value='64']";
    $vrf__[$ind_++] = "//div[text()='User Activated']/ancestor::div//option[text()='ENABLED']";
    $vrf__[$ind_++] = "//div[text()='Network Appearance']/ancestor::div//input[\@value='UNSET']";

	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets'" );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }
    #click LS 051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets 051.051.051'" );
        print FH "STEP: Click the 'Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Linksets 051.051.051' - Pass \n";
    }
    #click genneric Link Selection
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_generic_link)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Generic Link Selection 051.051.051'" );
        print FH "STEP: Click the 'Generic Link Selection 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Generic Link Selection 051.051.051' - Pass \n";
    }
    #verify
    foreach(@vrf__){
        my ($ind_) = $_ =~ /((?<=\/\/div\[text\(\)=')[A-Za-z\d\s]*(?='\]))/;
        unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $_)) {
            $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the $ind_" );
            print FH "STEP: Verify the $ind_ - Fail \n";
            $result = 0;
        } else {
            print FH "STEP: Verify the $ind_ - Pass \n";
        }      
    }
 
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
} 


sub ADQ_1411_Auto_MTP3_75 { #Verify Generic link
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_75");
    my $sub_name = "ADQ_1411_Auto_MTP3_75";
	my $tcid = "ADQ_1411_Auto_MTP3_75";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:2:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:2:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }

    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }

    #Add Generic link
    unless(grep/:ADD-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-SLK::50-51.51.51-0:CTAG::::GENERIC:LINK_TYPE=M3UA_SG,DRE_ID=3;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add Generic Link by command 'ADD-SLK::50-51.51.51-0:CTAG::::GENERIC:LINK_TYPE=M3UA_SG,DRE_ID=3;'" );
        print FH "STEP: Add Generic link by command 'ADD-SLK::50-51.51.51-0:CTAG::::GENERIC:LINK_TYPE=M3UA_SG,DRE_ID=3;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add Generic link by command 'ADD-SLK::50-51.51.51-0:CTAG::::GENERIC:LINK_TYPE=M3UA_SG,DRE_ID=3;' - PASS \n";  
    }
    #Change Generic link
    unless(grep/:CHG-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-SLK::50-51.51.51-0:CTAG::::GENERIC:LOCAL_IPADDR1=10.91.2.128,LOCAL_PORT=5000,REMOTE_IPADDR1=10.91.2.129,REMOTE_PORT=5001;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change Generic link by command 'CHG-SLK::50-51.51.51-0:CTAG::::GENERIC:LOCAL_IPADDR1=10.91.2.128,LOCAL_PORT=5000,REMOTE_IPADDR1=10.91.2.129,REMOTE_PORT=5001;'  " );
        print FH "STEP: Change Generic link by command 'CHG-SLK::50-51.51.51-0:CTAG::::GENERIC:LOCAL_IPADDR1=10.91.2.128,LOCAL_PORT=5000,REMOTE_IPADDR1=10.91.2.129,REMOTE_PORT=5001;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change Generic linkA by command 'CHG-SLK::50-51.51.51-0:CTAG::::GENERIC:LOCAL_IPADDR1=10.91.2.128,LOCAL_PORT=5000,REMOTE_IPADDR1=10.91.2.129,REMOTE_PORT=5001;' - PASS \n";  
    }
    #Verify Generic link
    unless(grep/:VFY-SLK-GENERIC:CTAG:COMPLD/,$ses_CLI1->execCmd("VFY-SLK-GENERIC::50-51.51.51-0:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify Generic link by command 'VFY-SLK-GENERIC::50-51.51.51-0:CTAG;'  " );
        print FH "STEP: Verify Generic link by command 'VFY-SLK-GENERIC::50-51.51.51-0:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Verify Generic link by command 'VFY-SLK-GENERIC::50-51.51.51-0:CTAG;' - PASS \n";  
    }
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url_128)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url_128" );
        print FH "STEP: Launch the url '$url_128' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url_128' - PASS \n";
    }
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    
    #---click Linksets
    my $xpath_linksets = "//span[contains (text(), 'Linksets')]";
    my $xpath_ls_2 = "//a[text() = 'LS 051.051.051' ]";
    my $xpath_generic_link = "//a[text()='051.051.051-00']";
    #verify Generic Link Configuration
    my (@vrf__, $ind_);
    $vrf__[$ind_++] = "//div[text()='Context']/ancestor::div//span[text()='051.051.051-00']";
    $vrf__[$ind_++] = "//div[text()='SLC']/ancestor::div[1]//span[text()='0']";
    $vrf__[$ind_++] = "//div[text()='Link Type']/ancestor::div[1]//span[text()='M3UA_SG']";
    $vrf__[$ind_++] = "//div[text()='DRE ID']/ancestor::div//span[text()='3']";
    $vrf__[$ind_++] = "//div[text()='Local IP Address 1']/ancestor::div//input[\@value='10.91.2.128']";
    $vrf__[$ind_++] = "//div[text()='Local IP Address 2']/ancestor::div[1]//input";
    $vrf__[$ind_++] = "//div[text()='Local Port']/ancestor::div[1]//input[\@value='5000']";
    $vrf__[$ind_++] = "//div[text()='Remote IP Address 1']/ancestor::div//input[\@value='10.91.2.129']";
    $vrf__[$ind_++] = "//div[text()='Remote IP Address 2']/ancestor::div[1]//input";
    $vrf__[$ind_++] = "//div[text()='Remote Port']/ancestor::div//input[\@value='5001']";
    $vrf__[$ind_++] = "//div[text()='L2 State']/ancestor::div//span[text()='OUT_OF_SERVICE']";
    $vrf__[$ind_++] = "//div[text()='L3 State']/ancestor::div//span[text()='DEACTIVATED']";
    $vrf__[$ind_++] = "//div[text()='Rx MSU Count']/ancestor::div[1]//span[text()='0']";
    $vrf__[$ind_++] = "//div[text()='Tx MSU Count']/ancestor::div[1]//span[text()='0']";
    $vrf__[$ind_++] = "//div[text()='Diagnostic Message']/ancestor::div//span[text()='Configured']";
    $vrf__[$ind_++] = "//div[text()='DataLink Bandwidth']/ancestor::div//input[\@value='64']";
    $vrf__[$ind_++] = "//div[text()='Alarms']/ancestor::div//input[\@value='64']";
    $vrf__[$ind_++] = "//div[text()='User Activated']/ancestor::div//option[text()='ENABLED']";
    $vrf__[$ind_++] = "//div[text()='Network Appearance']/ancestor::div//input[\@value='UNSET']";
    #verify debug configuration
    my $xpath_debug_configuration = "//a[contains(text(),'Debug Configuration')]";
    my (@vrf_debug_, $ind_);
    $vrf_debug_[$ind_++] = "//div[text()='Data Debug Level']/ancestor::div[1]//input[\@value='1']";
    $vrf_debug_[$ind_++] = "//div[text()='Software Debug Level']/ancestor::div[1]//input[\@value='1']";
    #verify SCTP configuration
    my $xpath_SCTP = "//a[contains(text(),'SCTP Configuration')]";
    my (@vrf_sctp_conf_, $ind__);
    $vrf_sctp_conf_[$ind__++] = "//div[contains(text(),'Linkset SCTP Values')]/ancestor::div//option[\@value='YES']";
    $vrf_sctp_conf_[$ind__++] = "//div[contains(text(),'Heartbeat')]/ancestor::div[1]//option[\@value='ENABLED']";
    $vrf_sctp_conf_[$ind__++] = "//div[contains(text(),'Heartbeat Interval')]/ancestor::div//input[\@value='150']";
    $vrf_sctp_conf_[$ind__++] = "//div[contains(text(),'RTO Initial')]/ancestor::div[1]//input[\@value='180']";
    $vrf_sctp_conf_[$ind__++] = "//div[contains(text(),'RTO Minimum')]/ancestor::div[1]//input[\@value='180']";
    $vrf_sctp_conf_[$ind__++] = "//div[contains(text(),'RTO Maximum')]/ancestor::div//input[\@value='250']";
    $vrf_sctp_conf_[$ind__++] = "//div[contains(text(),'Maximum Path Retrans')]/ancestor::div//input[\@value='10']";
    $vrf_sctp_conf_[$ind__++] = "//div[contains(text(),'Maximum Assoc Retrans')]/ancestor::div//input[\@value='15']";
    $vrf_sctp_conf_[$ind__++] = "//div[contains(text(),'Bundling')]/ancestor::div[1]//option[\@value='ENABLED']";
    $vrf_sctp_conf_[$ind__++] = "//div[contains(text(),'Bundling TO')]/ancestor::div[1]//input[\@value='20']";
    $vrf_sctp_conf_[$ind__++] = "//div[contains(text(),'Delayed ACK TO')]/ancestor::div[1]//input[\@value='20']";
    $vrf_sctp_conf_[$ind__++] = "//div[contains(text(),'Fast Retrans Threshold')]/ancestor::div[1]//input[\@value='4']";
    $vrf_sctp_conf_[$ind__++] = "//div[contains(text(),'Checksum')]/ancestor::div//span[text()='CRC32C']";
    $vrf_sctp_conf_[$ind__++] = "//div[contains(text(),'In Streams')]/ancestor::div[1]//input[\@value='256']";
    $vrf_sctp_conf_[$ind__++] = "//div[contains(text(),'Out Streams')]/ancestor::div[1]//input[\@value='256']";


	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets'" );
        print FH "STEP: Click the ' Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the ' Linksets' - Pass \n";
    }
    #click LS 051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the ' Linksets 051.051.051'" );
        print FH "STEP: Click the 'Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Linksets 051.051.051' - Pass \n";
    }
    #click genneric Link Selection
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_generic_link)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Generic Link Selection 051.051.051'" );
        print FH "STEP: Click the 'Generic Link Selection 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Generic Link Selection 051.051.051' - Pass \n";
    }
    #verify Generic Link Configuration
    foreach(@vrf__){
        my ($ind_) = $_ =~ /((?<=\/\/div\[text\(\)=')[A-Za-z\d\s]*(?='\]))/;
        unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $_)) {
            $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the $ind_" );
            print FH "STEP: Verify the $ind_ - Fail \n";
            $result = 0;
        } else {
            print FH "STEP: Verify the $ind_ - Pass \n";
        }      
    }
    #click Debug Configuration
    unless ($ses_Selenium->clickElement(-xPath => $xpath_debug_configuration)) {
        $logger->error(__PACKAGE__ . ": Failed to click 'Debug Configuration' button" );
        print FH "STEP: Click 'Debug Configuration' button - FAIL \n";
        return 0;
    } else {
        print FH "STEP: Click 'Debug Configuration' button - PASS \n";
    }
    #verify Debug Configuration
    foreach(@vrf_debug_){
        my ($ind_) = $_ =~ /((?<=\/\/div\[text\(\)=')[A-Za-z\d\s]*(?='\]))/;
        unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $_)) {
            $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the $ind_" );
            print FH "STEP: Verify the $ind_ - Fail \n";
            $result = 0;
        } else {
            print FH "STEP: Verify the $ind_ - Pass \n";
        }      
    }
    #click SCTP Configuration
    unless ($ses_Selenium->clickElement(-xPath => $xpath_SCTP)) {
        $logger->error(__PACKAGE__ . ": Failed to click 'SCTP Configuration' button" );
        print FH "STEP: Click 'SCTP Configuration' button - FAIL \n";
        return 0;
    } else {
        print FH "STEP: Click 'SCTP Configuration' button - PASS \n";
    }
    #verify SCTP Configuration
    foreach(@vrf_sctp_conf_){
        my ($ind__) = $_ =~ /((?<=\/\/div\[contains\(text\(\),')[A-Za-z\d\s]*(?='\)]))/;
        unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $_)) {
            $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the $ind__" );
            print FH "STEP: Verify the $ind__ - Fail \n";
            $result = 0;
        } else {
            print FH "STEP: Verify the $ind__ - Pass \n";
        }      
    }
 
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
} 

sub ADQ_1411_Auto_MTP3_76 { #Delete Generic link
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_76");
    my $sub_name = "ADQ_1411_Auto_MTP3_76";
	my $tcid = "ADQ_1411_Auto_MTP3_76";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:2:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:2:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:2:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }

    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }

    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }

    #Add Generic link
    unless(grep/:ADD-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-SLK::50-51.51.51-0:CTAG::::GENERIC:LINK_TYPE=M3UA_SG,DRE_ID=3;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add Generic Link by command 'ADD-SLK::50-51.51.51-0:CTAG::::GENERIC:LINK_TYPE=M3UA_SG,DRE_ID=3;'" );
        print FH "STEP: Add Generic link by command 'ADD-SLK::50-51.51.51-0:CTAG::::GENERIC:LINK_TYPE=M3UA_SG,DRE_ID=3;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add Generic link by command 'ADD-SLK::50-51.51.51-0:CTAG::::GENERIC:LINK_TYPE=M3UA_SG,DRE_ID=3;' - PASS \n";  
    }

    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url_128)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url_128" );
        print FH "STEP: Launch the url '$url_128' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url_128' - PASS \n";
    }
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    #click NA50
    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    
    #---click Linksets
    my $xpath_linksets = "//span[contains(text(),'Linksets')]";
    my $xpath_ls_2 = "//a[text()='LS 051.051.051']";
    my $xpath_generic_link = "//a[text()='051.051.051-00']";
   
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_linksets)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Linksets'" );
        print FH "STEP: Click the 'Linksets' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Linksets' - Pass \n";
    }
    #click LS 051.051.051
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_ls_2)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Linksets 051.051.051'" );
        print FH "STEP: Click the 'Linksets 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Linksets 051.051.051' - Pass \n";
    }
    #click genneric Link Selection
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $xpath_generic_link)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Generic Link Selection 051.051.051'" );
        print FH "STEP: Click the 'Generic Link Selection 051.051.051' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Generic Link Selection 051.051.051' - Pass \n";
    }
    #Delete Generic link
    unless(grep/:DLT-SLK:CTAG:COMPLD;/,$ses_CLI1->execCmd("DLT-SLK::50-51.51.51-0:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Delete Generic link by command 'DLT-SLK::50-51.51.51-0:CTAG;'" );
        print FH "STEP: Delete Generic link by command 'DLT-SLK::50-51.51.51-0:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Delete Generic link by command 'DLT-SLK::50-51.51.51-0:CTAG;' - PASS \n";  
    }
    
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
} 


sub ADQ_1411_Auto_MTP3_77 { #Change NA with TTC vairiant 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_77");
    my $sub_name = "ADQ_1411_Auto_MTP3_77";
	my $tcid = "ADQ_1411_Auto_MTP3_77";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:1:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    unless(grep/:CHG-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-NA::50:CTAG:::::LOCAL_PC=5.4.7,SS7_VARIANT=TTC,PC_DISPLAY=5.4.7,PC_ROUTING=5.4.7,NET_IND=NI_10,CLLI=Autotest;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change NA by command 'CHG-NA::50:CTAG:::::LOCAL_PC=5.4.7,SS7_VARIANT=TTC,PC_DISPLAY=5.4.7,PC_ROUTING=5.4.7,NET_IND=NI_10,CLLI=Autotest;'" );
        print FH "STEP: Change NA by command 'CHG-NA::50:CTAG:::::LOCAL_PC=5.4.7,SS7_VARIANT=TTC,PC_DISPLAY=5.4.7,PC_ROUTING=5.4.7,NET_IND=NI_10,CLLI=Autotest;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change NA by command 'CHG-NA::50:CTAG:::::LOCAL_PC=5.4.7,SS7_VARIANT=TTC,PC_DISPLAY=5.4.7,PC_ROUTING=5.4.7,NET_IND=NI_10,CLLI=Autotest;' - PASS \n";  
    }
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url_128" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    # 
    my $vrf_na50_inactive = "//a[contains(text(),'NA 50')]/ancestor::tr//td[text()='INACTIVE']";
	unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_na50_inactive)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the inactive added NA50" );
        print FH "STEP: Verify the inactive added NA50 - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the inactive added NA50 - Pass \n";
    }

    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    my @vrf_;
    my $ind_;
    $vrf_[$ind_++] = "//div[contains(text(),'Context')]/following-sibling::div//span[text()='NA 50 05.04.007']";
    $vrf_[$ind_++] = "//div[contains(text(),'Local Point Code')]/following-sibling::div//input[\@value='05.04.007']";
    $vrf_[$ind_++] = "//div[contains(text(),'SS7 Variant')]/following-sibling::div//option[\@selected='selected' and text()='TTC']";
    $vrf_[$ind_++] = "//div[contains(text(),'PC Display Format')]/following-sibling::div//input[\@value='5.4.7']";
    $vrf_[$ind_++] = "//div[contains(text(),'PC Routing Format')]/following-sibling::div//input[\@value='5.4.7']";
    $vrf_[$ind_++] = "//div[contains(text(),'Network Indicator')]/following-sibling::div//option[\@selected='selected' and text()='NI_10']";
    $vrf_[$ind_++] = "//div[contains(text(),'Status')]/following-sibling::div//span[text()='INACTIVE']";
    $vrf_[$ind_++] = "//div[contains(text(),'CLLI')]/following-sibling::div//input[\@value='Autotest']";
    $vrf_[$ind_++] = "//div[contains(text(),'Network Appearance')]/following-sibling::div//span[text()='50']";

    foreach (@vrf_){
        my ($desc_) = $_ =~ /((?<=\/\/div\[contains\(text\(\),')[A-Za-z\d\s]*(?='\)]))/;
        unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $_)) {
            $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the $desc_" );
            print FH "STEP: Verify the $desc_ - Fail \n";
            $result = 0;
        } else {
            print FH "STEP: Verify the $desc_ - Pass \n";
        }       
    }
    
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}


sub ADQ_1411_Auto_MTP3_78 { #Change NA with NTT vairiant 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_78");
    my $sub_name = "ADQ_1411_Auto_MTP3_78";
	my $tcid = "ADQ_1411_Auto_MTP3_78";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:2:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;'" );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'" );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    unless(grep/:CHG-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-NA::50:CTAG:::::LOCAL_PC=5.4.7,SS7_VARIANT=NTT,PC_DISPLAY=5.4.7,PC_ROUTING=5.4.7,NET_IND=NI_01,CLLI=Autotest;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change NA by command 'CHG-NA::50:CTAG:::::LOCAL_PC=5.4.7,SS7_VARIANT=NTT,PC_DISPLAY=5.4.7,PC_ROUTING=5.4.7,NET_IND=NI_10,CLLI=Autotest;'" );
        print FH "STEP: Change NA by command 'CHG-NA::50:CTAG:::::LOCAL_PC=5.4.7,SS7_VARIANT=NTT,PC_DISPLAY=5.4.7,PC_ROUTING=5.4.7,NET_IND=NI_10,CLLI=Autotest;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change NA by command 'CHG-NA::50:CTAG:::::LOCAL_PC=5.4.7,SS7_VARIANT=NTT,PC_DISPLAY=5.4.7,PC_ROUTING=5.4.7,NET_IND=NI_10,CLLI=Autotest;' - PASS \n";  
    }
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    # 
    my $vrf_na50_inactive = "//a[contains(text(),'NA 50')]/ancestor::tr//td[text()='INACTIVE']";
	unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_na50_inactive)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the inactive added NA50" );
        print FH "STEP: Verify the inactive added NA50 - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the inactive added NA50 - Pass \n";
    }

    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    my @vrf_;
    my $ind_;
    $vrf_[$ind_++] = "//div[contains(text(),'Context')]/following-sibling::div//span[text()='NA 50 05.04.007']";
    $vrf_[$ind_++] = "//div[contains(text(),'Local Point Code')]/following-sibling::div//input[\@value='05.04.007']";
    $vrf_[$ind_++] = "//div[contains(text(),'SS7 Variant')]/following-sibling::div//option[\@selected='selected' and text()='NTT']";
    $vrf_[$ind_++] = "//div[contains(text(),'PC Display Format')]/following-sibling::div//input[\@value='5.4.7']";
    $vrf_[$ind_++] = "//div[contains(text(),'PC Routing Format')]/following-sibling::div//input[\@value='5.4.7']";
    $vrf_[$ind_++] = "//div[contains(text(),'Network Indicator')]/following-sibling::div//option[\@selected='selected' and text()='NI_01']";
    $vrf_[$ind_++] = "//div[contains(text(),'Status')]/following-sibling::div//span[text()='INACTIVE']";
    $vrf_[$ind_++] = "//div[contains(text(),'CLLI')]/following-sibling::div//input[\@value='Autotest']";
    $vrf_[$ind_++] = "//div[contains(text(),'Network Appearance')]/following-sibling::div//span[text()='50']";

    foreach (@vrf_){
        my ($desc_) = $_ =~ /((?<=\/\/div\[contains\(text\(\),')[A-Za-z\d\s]*(?='\)]))/;
        unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $_)) {
            $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the $desc_" );
            print FH "STEP: Verify the $desc_ - Fail \n";
            $result = 0;
        } else {
            print FH "STEP: Verify the $desc_ - Pass \n";
        }       
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_79 { #Change NA with CHINA vairiant 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_79");
    my $sub_name = "ADQ_1411_Auto_MTP3_79";
	my $tcid = "ADQ_1411_Auto_MTP3_79";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:2:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;'");
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing");
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;");
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    unless(grep/:CHG-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-NA::50:CTAG:::::LOCAL_PC=50.50.50,SS7_VARIANT=CHINA,PC_DISPLAY=8.8.8,PC_ROUTING=8.8.8,NET_IND=NI_01,CLLI=Autotest;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change NA by command 'CHG-NA::50:CTAG:::::LOCAL_PC=50.50.50,SS7_VARIANT=CHINA,PC_DISPLAY=8.8.8,PC_ROUTING=8.8.8,NET_IND=NI_01,CLLI=Autotest;'");
        print FH "STEP: Change NA by command 'CHG-NA::50:CTAG:::::LOCAL_PC=50.50.50,SS7_VARIANT=CHINA,PC_DISPLAY=8.8.8,PC_ROUTING=8.8.8,NET_IND=NI_01,CLLI=Autotest;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change NA by command 'CHG-NA::50:CTAG:::::LOCAL_PC=50.50.50,SS7_VARIANT=CHINA,PC_DISPLAY=8.8.8,PC_ROUTING=8.8.8,NET_IND=NI_01,CLLI=Autotest;' - PASS \n";  
    }
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    # 
    my $vrf_na50_inactive = "//a[contains(text(),'NA 50')]/ancestor::tr//td[text()='INACTIVE']";
	unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_na50_inactive)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the inactive added NA50" );
        print FH "STEP: Verify the inactive added NA50 - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the inactive added NA50 - Pass \n";
    }

    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    my @vrf_;
    my $ind_;
    $vrf_[$ind_++] = "//div[contains(text(),'Context')]/following-sibling::div//span[text()='NA 50 050.050.050']";
    $vrf_[$ind_++] = "//div[contains(text(),'Local Point Code')]/following-sibling::div//input[\@value='050.050.050']";
    $vrf_[$ind_++] = "//div[contains(text(),'SS7 Variant')]/following-sibling::div//option[\@selected='selected' and text()='CHINA']";
    $vrf_[$ind_++] = "//div[contains(text(),'PC Display Format')]/following-sibling::div//input[\@value='8.8.8']";
    $vrf_[$ind_++] = "//div[contains(text(),'PC Routing Format')]/following-sibling::div//input[\@value='8.8.8']";
    $vrf_[$ind_++] = "//div[contains(text(),'Network Indicator')]/following-sibling::div//option[\@selected='selected' and text()='NI_01']";
    $vrf_[$ind_++] = "//div[contains(text(),'Status')]/following-sibling::div//span[text()='INACTIVE']";
    $vrf_[$ind_++] = "//div[contains(text(),'CLLI')]/following-sibling::div//input[\@value='Autotest']";
    $vrf_[$ind_++] = "//div[contains(text(),'Network Appearance')]/following-sibling::div//span[text()='50']";

    foreach (@vrf_){
        my ($desc_) = $_ =~ /((?<=\/\/div\[contains\(text\(\),')[A-Za-z\d\s]*(?='\)]))/;
        unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $_)) {
            $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the $desc_" );
            print FH "STEP: Verify the $desc_ - Fail \n";
            $result = 0;
        } else {
            print FH "STEP: Verify the $desc_ - Pass \n";
        }       
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_80 { #Change NA with ANSI vairiant 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_80");
    my $sub_name = "ADQ_1411_Auto_MTP3_80";
	my $tcid = "ADQ_1411_Auto_MTP3_80";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:2:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    unless(grep/:CHG-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-NA::50:CTAG:::::LOCAL_PC=50.50.50,SS7_VARIANT=ANSI,PC_DISPLAY=8.8.8,PC_ROUTING=8.8.8,NET_IND=NI_01,CLLI=Autotest;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change NA by command 'CHG-NA::50:CTAG:::::LOCAL_PC=50.50.50,SS7_VARIANT=ANSI,PC_DISPLAY=8.8.8,PC_ROUTING=8.8.8,NET_IND=NI_01,CLLI=Autotest;'" );
        print FH "STEP: Change NA by command 'CHG-NA::50:CTAG:::::LOCAL_PC=50.50.50,SS7_VARIANT=ANSI,PC_DISPLAY=8.8.8,PC_ROUTING=8.8.8,NET_IND=NI_01,CLLI=Autotest;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change NA by command 'CHG-NA::50:CTAG:::::LOCAL_PC=50.50.50,SS7_VARIANT=ANSI,PC_DISPLAY=8.8.8,PC_ROUTING=8.8.8,NET_IND=NI_01,CLLI=Autotest;' - PASS \n";  
    }
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    # 
    my $vrf_na50_inactive = "//a[contains(text(),'NA 50')]/ancestor::tr//td[text()='INACTIVE']";
	unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_na50_inactive)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the inactive added NA50" );
        print FH "STEP: Verify the inactive added NA50 - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the inactive added NA50 - Pass \n";
    }

    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    my @vrf_;
    my $ind_;
    $vrf_[$ind_++] = "//div[contains(text(),'Context')]/following-sibling::div//span[text()='NA 50 050.050.050']";
    $vrf_[$ind_++] = "//div[contains(text(),'Local Point Code')]/following-sibling::div//input[\@value='050.050.050']";
    $vrf_[$ind_++] = "//div[contains(text(),'SS7 Variant')]/following-sibling::div//option[\@selected='selected' and text()='ANSI']";
    $vrf_[$ind_++] = "//div[contains(text(),'PC Display Format')]/following-sibling::div//input[\@value='8.8.8']";
    $vrf_[$ind_++] = "//div[contains(text(),'PC Routing Format')]/following-sibling::div//input[\@value='8.8.8']";
    $vrf_[$ind_++] = "//div[contains(text(),'Network Indicator')]/following-sibling::div//option[\@selected='selected' and text()='NI_01']";
    $vrf_[$ind_++] = "//div[contains(text(),'Status')]/following-sibling::div//span[text()='INACTIVE']";
    $vrf_[$ind_++] = "//div[contains(text(),'CLLI')]/following-sibling::div//input[\@value='Autotest']";
    $vrf_[$ind_++] = "//div[contains(text(),'Network Appearance')]/following-sibling::div//span[text()='50']";

    foreach (@vrf_){
        my ($desc_) = $_ =~ /((?<=\/\/div\[contains\(text\(\),')[A-Za-z\d\s]*(?='\)]))/;
        unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $_)) {
            $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the $desc_" );
            print FH "STEP: Verify the $desc_ - Fail \n";
            $result = 0;
        } else {
            print FH "STEP: Verify the $desc_ - Pass \n";
        }       
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_81 { #Change NA with ANSI vairiant 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_81");
    my $sub_name = "ADQ_1411_Auto_MTP3_81";
	my $tcid = "ADQ_1411_Auto_MTP3_81";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:2:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    unless(grep/:CHG-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-NA::50:CTAG:::::LOCAL_PC=50.50.50,SS7_VARIANT=ANSI,PC_DISPLAY=8.8.8,PC_ROUTING=8.8.8,NET_IND=NI_11,CLLI=Autotest;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change NA by command 'CHG-NA::50:CTAG:::::LOCAL_PC=50.50.50,SS7_VARIANT=ANSI,PC_DISPLAY=8.8.8,PC_ROUTING=8.8.8,NET_IND=NI_11,CLLI=Autotest;'" );
        print FH "STEP: Change NA by command 'CHG-NA::50:CTAG:::::LOCAL_PC=50.50.50,SS7_VARIANT=ANSI,PC_DISPLAY=8.8.8,PC_ROUTING=8.8.8,NET_IND=NI_11,CLLI=Autotest;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change NA by command 'CHG-NA::50:CTAG:::::LOCAL_PC=50.50.50,SS7_VARIANT=ANSI,PC_DISPLAY=8.8.8,PC_ROUTING=8.8.8,NET_IND=NI_11,CLLI=Autotest;' - PASS \n";  
    }
    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    # 
    my $vrf_na50_inactive = "//a[contains(text(),'NA 50')]/ancestor::tr//td[text()='INACTIVE']";
	unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_na50_inactive)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the inactive added NA50" );
        print FH "STEP: Verify the inactive added NA50 - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the inactive added NA50 - Pass \n";
    }

    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    my @vrf_;
    my $ind_;
    $vrf_[$ind_++] = "//div[contains(text(),'Context')]/following-sibling::div//span[text()='NA 50 050.050.050']";
    $vrf_[$ind_++] = "//div[contains(text(),'Local Point Code')]/following-sibling::div//input[\@value='050.050.050']";
    $vrf_[$ind_++] = "//div[contains(text(),'SS7 Variant')]/following-sibling::div//option[\@selected='selected' and text()='ANSI']";
    $vrf_[$ind_++] = "//div[contains(text(),'PC Display Format')]/following-sibling::div//input[\@value='8.8.8']";
    $vrf_[$ind_++] = "//div[contains(text(),'PC Routing Format')]/following-sibling::div//input[\@value='8.8.8']";
    $vrf_[$ind_++] = "//div[contains(text(),'Network Indicator')]/following-sibling::div//option[\@selected='selected' and text()='NI_11']";
    $vrf_[$ind_++] = "//div[contains(text(),'Status')]/following-sibling::div//span[text()='INACTIVE']";
    $vrf_[$ind_++] = "//div[contains(text(),'CLLI')]/following-sibling::div//input[\@value='Autotest']";
    $vrf_[$ind_++] = "//div[contains(text(),'Network Appearance')]/following-sibling::div//span[text()='50']";

    foreach (@vrf_){
        my ($desc_) = $_ =~ /((?<=\/\/div\[contains\(text\(\),')[A-Za-z\d\s]*(?='\)]))/;
        unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $_)) {
            $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the $desc_" );
            print FH "STEP: Verify the $desc_ - Fail \n";
            $result = 0;
        } else {
            print FH "STEP: Verify the $desc_ - Pass \n";
        }       
    }
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_82 { #Change Linkset with B link 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_82");
    my $sub_name = "ADQ_1411_Auto_MTP3_82";
	my $tcid = "ADQ_1411_Auto_MTP3_82";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:2:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    unless(grep/:CHG-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-LS::50-51.51.51:CTAG:::::LINKT=B_LINK;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change NA by command 'CHG-LS::50-51.51.51:CTAG:::::LINKT=B_LINK;'" );
        print FH "STEP: Change NA by command 'CHG-LS::50-51.51.51:CTAG:::::LINKT=B_LINK;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change NA by command 'CHG-LS::50-51.51.51:CTAG:::::LINKT=B_LINK;' - PASS \n";  
    }

    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    # 
    my $vrf_na50_inactive = "//a[contains(text(),'NA 50')]/ancestor::tr//td[text()='INACTIVE']";
	unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_na50_inactive)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the inactive added NA50" );
        print FH "STEP: Verify the inactive added NA50 - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the inactive added NA50 - Pass \n";
    }

    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    my $linkset_tab = "//span[text()='Linksets']";
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $linkset_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Linkset' tab" );
        print FH "STEP: Click the 'Linkset' tab - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Linkset' tab - Pass \n";
    }
    my $linkset = "//a[text()='LS 051.051.051']";
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $linkset)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Linkset'" );
        print FH "STEP: Click the 'Linkset' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Linkset' - Pass \n";
    }
    my $vrf_link_type = "//div[text()='Link Type']/following-sibling::div//option[\@selected='selected' and text()='B_LINK']";
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_link_type)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the Link Type" );
        print FH "STEP: Verify the Link Type - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the Link Type - Pass \n";
    }
    
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}


sub ADQ_1411_Auto_MTP3_83 { #Change Linkset with C link 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_83");
    my $sub_name = "ADQ_1411_Auto_MTP3_83";
	my $tcid = "ADQ_1411_Auto_MTP3_83";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:2:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    unless(grep/:CHG-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-LS::50-51.51.51:CTAG:::::LINKT=C_LINK;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change NA by command 'CHG-LS::50-51.51.51:CTAG:::::LINKT=C_LINK;'" );
        print FH "STEP: Change NA by command 'CHG-LS::50-51.51.51:CTAG:::::LINKT=C_LINK;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change NA by command 'CHG-LS::50-51.51.51:CTAG:::::LINKT=C_LINK;' - PASS \n";  
    }

    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    # 
    my $vrf_na50_inactive = "//a[contains(text(),'NA 50')]/ancestor::tr//td[text()='INACTIVE']";
	unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_na50_inactive)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the inactive added NA50" );
        print FH "STEP: Verify the inactive added NA50 - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the inactive added NA50 - Pass \n";
    }

    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    my $linkset_tab = "//span[text()='Linksets']";
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $linkset_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Linkset' tab" );
        print FH "STEP: Click the 'Linkset' tab - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Linkset' tab - Pass \n";
    }
    my $linkset = "//a[text()='LS 051.051.051']";
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $linkset)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Linkset'" );
        print FH "STEP: Click the 'Linkset' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Linkset' - Pass \n";
    }
    my $vrf_link_type = "//div[text()='Link Type']/following-sibling::div//option[\@selected='selected' and text()='C_LINK']";
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_link_type)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the Link Type" );
        print FH "STEP: Verify the Link Type - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the Link Type - Pass \n";
    }
    
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}

sub ADQ_1411_Auto_MTP3_84 { #Change Linkset with D link 
    $logger->debug(__PACKAGE__ . " Inside test case ADQ_1411_Auto_MTP3_84");
    my $sub_name = "ADQ_1411_Auto_MTP3_84";
	my $tcid = "ADQ_1411_Auto_MTP3_84";
	my $result= 1;
	my $flag = 1;
    
    my $executionLogs = $sub_name.'_'.$tcid.'_ExecutionLogs_'.$datestamp.'.txt';
    my $Image_Path = $imagePath."_".$tcid.'_IMAGE_'.$datestamp.'.png';

    open(FH,'>',$executionLogs) or die $!;
    move($dir."/".$executionLogs,"/home/$ENV{ USER }/ats_user/logs/ADQ_1411");
   
############### Test Specific configuration & Test Tool Script Execution ################# 
	######################################################### 	
	unless($ses_CLI1 = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "c20:1:ce0"},-sessionLog => "$sub_name"."_audit_Logs")){
	   $logger->error(__PACKAGE__ . ".$sub_name : Could not create DCR object for tms_alias => TESTBED{ c20:2:ce0’ }");
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - FAILED\n";
	   goto CLEANUP;          
	} else {
	   print FH "STEP: Login to DCR with user \"$TESTBED{\"c20:1:ce0:hash\"}->{\"LOGIN\"}->{1}->{\"USERID\"}\"  - PASSED\n";
	}

	# Switch to TL1 mode 
	$ses_CLI1->{conn}->prompt('/PTI_TL1>/');
	unless(grep/Connected to localhost/, $ses_CLI1->execCmd("telnet localhost 6669")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Execute command 'telnet localhost 6669' " );
        print FH "STEP: Execute command 'telnet localhost 6669' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Execute command 'telnet localhost 6669' - PASS \n";
    }	    

	unless(grep/COMPLD/, $ses_CLI1->execCmd("act-user::root:::$dcr_passwd;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Login to TL1 using command 'act-user::root:::$dcr_passwd;' " );
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Login to TL1 using command 'act-user::root:::$dcr_passwd;' - PASS \n";
    }	

    unless(cleanup_mtp3($ses_CLI1)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Clean up before testing" );
        print FH "STEP: Clean up before testing - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Clean up before testing - PASS \n";  
    }
    unless(grep/:ADD-NA:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-NA::$NA_50:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add NA by command 'ADD-NA::$NA_50:CTAG;'  " );
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add NA by command 'ADD-NA::$NA_50:CTAG;' - PASS \n";  
    }
    #Add Linkset
    unless(grep/:ADD-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("ADD-LS::50-51.51.51:CTAG;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;'  " );
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Add LINKSET by command 'ADD-LS::50-51.51.51:CTAG;' - PASS \n";  
    }
    unless(grep/:CHG-LS:CTAG:COMPLD;/,$ses_CLI1->execCmd("CHG-LS::50-51.51.51:CTAG:::::LINKT=D_LINK;")) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Change NA by command 'CHG-LS::50-51.51.51:CTAG:::::LINKT=D_LINK;'" );
        print FH "STEP: Change NA by command 'CHG-LS::50-51.51.51:CTAG:::::LINKT=D_LINK;' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    }else{
        print FH "STEP: Change NA by command 'CHG-LS::50-51.51.51:CTAG:::::LINKT=D_LINK;' - PASS \n";  
    }

    ## Go to url 
    my ($sessionId, $localUrl);
    
	unless($ses_Selenium = SonusQA::ATSHELPER::newFromAlias(-tms_alias => $TESTBED{ "selenium:1:ce0"}, -sessionlog => $sub_name."_ConsoleLogs", -output_record_separator => "\n")){
		$logger->error(__PACKAGE__ . ".$tcid: Could not create Selenium object for tms_alias => TESTBED{ ‘selenium:1:ce0’ }");
        $result = 0;
        goto CLEANUP;          
	}
   
    unless (($sessionId, $localUrl) = $ses_Selenium->initialize(-sourceCodePath => $seleniumSource, -browser => $browser, -url => $url)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to launch  URL: $url" );
        print FH "STEP: Launch the url '$url' - FAIL \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Launch the url '$url' - PASS \n";
    }
   
    ### Login CMU
	unless (&login($ses_Selenium)) {
        $result = 0;
        goto CLEANUP;
    }	
    # Click MTP3 tab
	my $mtp3_tab = "//a[contains(text(),'MTP3')]";    
    unless ($ses_Selenium->clickElement(-xPath => $mtp3_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click 'MTP3' tab" );
        print FH "STEP: Click 'MTP3' tab - FAIL \n";
        $result = 0;
		goto CLEANUP;
    } else {
        print FH "STEP: Click 'MTP3' tab - PASS \n";
    }   
    # 
    my $vrf_na50_inactive = "//a[contains(text(),'NA 50')]/ancestor::tr//td[text()='INACTIVE']";
	unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_na50_inactive)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the inactive added NA50" );
        print FH "STEP: Verify the inactive added NA50 - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the inactive added NA50 - Pass \n";
    }

    my $na50 = "//a[contains(text(),'NA 50')]";
	unless ($ses_Selenium->javaScriptExeClick(-xPath => $na50)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'NA 50'" );
        print FH "STEP: Click the 'NA 50' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'NA 50' - Pass \n";
    }
    my $linkset_tab = "//span[text()='Linksets']";
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $linkset_tab)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Linkset' tab" );
        print FH "STEP: Click the 'Linkset' tab - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Linkset' tab - Pass \n";
    }
    my $linkset = "//a[text()='LS 051.051.051']";
    unless ($ses_Selenium->javaScriptExeClick(-xPath => $linkset)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Click the 'Linkset'" );
        print FH "STEP: Click the 'Linkset' - Fail \n";
        $result = 0;
        goto CLEANUP;
    } else {
        print FH "STEP: Click the 'Linkset' - Pass \n";
    }
    my $vrf_link_type = "//div[text()='Link Type']/following-sibling::div//option[\@selected='selected' and text()='D_LINK']";
    unless ($ses_Selenium->inspect(-action => "isdisplayed", -xPath => $vrf_link_type)) {
        $logger->error(__PACKAGE__ . ".$tcid: Failed to Verify the Link Type" );
        print FH "STEP: Verify the Link Type - Fail \n";
        $result = 0;
    } else {
        print FH "STEP: Verify the Link Type - Pass \n";
    }
    
############################ CLEANUP #############################
	CLEANUP: 
	$logger->info(__PACKAGE__ . ".$tcid: ============== CLEANUP ==============  " );
    $ses_CLI1->execCmd("\x1D",2);
	$ses_CLI1->{conn}->prompt($ses_CLI1->{DEFAULTPROMPT});
    $ses_CLI1->execCmd("quit",2);
    close(FH);
    &cleanup();
    # check the result var to know the TC is passed or failed
    &checkResult($tcid, $result); 
}





sub AUTOLOAD {
  
    our $AUTOLOAD;
  
    my $warn = "$AUTOLOAD  ATTEMPT TO CALL $AUTOLOAD FAILED (INVALID TEST)";
  
    if( Log::Log4perl::initialized() ) {
        
        my $logger = Log::Log4perl->get_logger($AUTOLOAD);
        $logger->warn( $warn );
    }
    else {
        Log::Log4perl->easy_init($DEBUG);
        WARN($warn);
    }
}

1;
