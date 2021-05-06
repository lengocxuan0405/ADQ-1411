#!/ats/bin/perl 

use strict; 
use warnings;

      
use Log::Log4perl qw(get_logger :levels);

use QATEST::DSC::DCR_2_0::ADQ_1411::ADQ_1411; 

#####################################
# TESTS
#####################################

our $TESTSUITE;

$TESTSUITE->{TESTED_RELEASE} = "V19.00.00";  
$TESTSUITE->{TESTED_VARIANT} = "DCR"; 
$TESTSUITE->{BUILD_VERSION} = "SBX_V05.00.05R000"; 

# $TESTSUITE->{TESTED_RELEASE} = "GBV.C20_R21";
# $TESTSUITE->{BUILD_VERSION} = "C20-CORE_xsnn17cf";
# $TESTSUITE->{TESTED_VARIANT} = "GBV.C20_R21";


$TESTSUITE->{PATH} = '/home/$ENV{ USER }/ats_user/logs/'.$TESTSUITE->{TESTED_RELEASE};   # CGE Log Path to Store Server logs and Core Files. 

# NOTE: Email ID of test suite executer is added by default.
$TESTSUITE->{EMAIL_LIST}	= [
     'hvtung@tma.com.vn',
];   # Email Group


our $release = $TESTSUITE->{TESTED_RELEASE};
our $build = $TESTSUITE->{BUILD_VERSION};
our @emailList	= @{$TESTSUITE->{EMAIL_LIST}};

print "************  RELEASE	==> $release \tBUILD ==> $build \n";
print "************  EMAIL_LIST ==> @emailList\n";

#####################################
# EXECUTION OF TESTS
#####################################

&QATEST::DSC::DCR_2_0::ADQ_1411::ADQ_1411::runTests;  ################  For running all tests #########################

#&QATEST::DSC::DCR_2_0::ADQ_1411::ADQ_1411::runTests("ADQ_1411_Auto_MTP3_28");  ################  For running selective tests #########################

1;
