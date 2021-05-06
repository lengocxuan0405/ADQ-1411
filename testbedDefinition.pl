#!/ats/bin/perl

#####################################
# TEST BED DEFINITION
#####################################

# Define the testbed as an array. Group elements of redundant systems together. For example
#
# our @TESTBED = (
#                   [ "asterix", "obelix" ],    <-- SGX4000 Dual CE
#                   "viper",                    <-- GSX1
#                   "wookie",                   <-- PSX1
#                   "tomcat",                   <-- GSX2
#
# The order in which the like devices are specfied will be the order in which they are referenced
# later. Ie. in the above example there are 2 GSXs, VIPER and TOMCAT. As VIPER is declared first 
# it will become GSX1 and so TOMCAT is GSX2 and so on.
# 
# For the SGX systems there will always be a notion of CEs: the first device specified (asterix) becomes
# CE0, the second device specified (viper) is CE1, they are both referred to as the first SGX4000. For
# single CE systems, they will just be the CE0 for that system.
 


our @TESTBED = (
		"DCR96",
		"DSC8K_128", # C20 object
		"Selenium_Server53"
                );
