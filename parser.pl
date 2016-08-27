#!/usr/bin/perl
$urbrequest=0;
use Switch;

$enabled=1;
$setuppacket=0;
$urbrequest="000001";
$selectinterface=0;
$enabledisoc=1;
$direction=0;
$dir_out = 0;
$bulk = 0;
$dir_in = 1;
my %urbhash=();
while (<>){
#  <<<  URB 1 coming back  <<<
# [42 ms]  >>>  URB 2 going down  >>>
        if(/>>>/){
                if(/\[(\d{1,}) ms\]  >>>  URB (\d{1,})/){
                        $urbrequest=sprintf("%06d",$2);
                        $timing=$1;
                }
                $enabled=1;
		$bulk=0;
                $setuppacket=0;
                $selectinterface=0;
		$direction=$dir_out
        }
        if(/<<</){
                if(/\[(\d{1,}) ms\]  <<<  URB (\d{1,})/){
                        $urbrequest=sprintf("%06d",$2);
                        $timing=$1;
                }
                $enabled=1;
		$bulk=0;
                $setuppacket=0;
                $selectinterface=0;
		$direction=$dir_in;
        }
        if(/ISOCH_TRANSFER/){
                $enabled=0;
                ${$urbhash{$urbrequest}{'remark'}}[0]="ISOCH_TRANSFER - (not parsed)\n";
        }
        $urbhash{$urbrequest}{'timing'}=$timing;
        if($selectinterface==1){
        # Interface: AlternateSetting  = 7
                if(/Interface: AlternateSetting  = (\d{1,})/){
                        push(@{$urbhash{$urbrequest}{'remark'}},sprintf("Changing to Alternative Setting [%05x]\n",hex($1)));
                }
        }
        if(/URB_FUNCTION_SELECT_INTERFACE/){
                $selectinterface=1;
        }
        if(/URB_FUNCTION_RESET_PIPE/){
                push(@{$urbhash{$urbrequest}{'remark'}},"Function reset pipe (look at the logs)\n");
        }
        if(/URB_FUNCTION_GET_CURRENT_FRAME_NUMBER/){
                push(@{$urbhash{$urbrequest}{'remark'}},"FUNCTION_GET_CURRENT_FRAME_NUMBER (look at the logs)\n");
        }
        if(/URB_FUNCTION_SELECT_CONFIGURATION/){
                push(@{$urbhash{$urbrequest}{'remark'}},"URB_FUNCTION_SELECT_CONFIGURATION\n");
        }
        if($enabled==1){
                if($setuppacket==1){
                        if(/\d{4}: (.*)/){
				foreach $idb (keys %{$urbhash{$urbrequest}}){
					if($idb eq "out"){
						printlog();
						%urbhash=();
					}
				}
				push(@{$urbhash{$urbrequest}{'out'}},$1);
                        }
                        $urbhash{$urbrequest}{'timing'}=$timing;
                } else {
                        if(/\d{4}: (.*)/){
				if($urbhash{$urbrequest}{'type'} eq "bulk" and $direction == $dir_out) {
					       push(@{$urbhash{$urbrequest}{'out'}},$1);
				} elsif ($urbhash{$urbrequest}{'type'} eq "bulk" and $direction == $dir_in) {
					       push(@{$urbhash{$urbrequest}{'in'}},$1);
				} else {
					       push(@{$urbhash{$urbrequest}{'in'}},$1);
				}
			}
                }
                if(/SetupPacket.*/){
                        $setuppacket=1;
                }
		if(/endpoint (.*)\]/){
			$endpoint = substr($1,-5,5);
			if($bulk=1){
				$urbhash{$urbrequest}{'endpoint'}=$endpoint;
			}
		}
		if(/URB_FUNCTION_CONTROL_TRANSFER/){
			$urbhash{$urbrequest}{'type'}="control";
		} elsif(/URB_FUNCTION_BULK_OR_INTERRUPT_TRANSFER/){
			$urbhash{$urbrequest}{'type'}="bulk";
			$bulk=1;
		}
        } 
	
}

printlog(%urbhash);

# perl allows really dirty tricks
sub printlog{
	print "------------- NEW CAPTURED SESSION -----------\n";
	foreach $indexkey (sort keys %urbhash){
		if ($urbhash{$indexkey}{'type'} eq "control" ){
			print "$indexkey:  ";
			if($urbhash{$indexkey}{'remark'}[0] ne ""){
				print $urbhash{$indexkey}{'remark'}[0];
				next;
			}
			print "OUT: ";
			printf("%06d ms %06d ms ",$urbhash{sprintf("%06d",($indexkey+1))}{'timing'}-$urbhash{$indexkey}{'timing'},$urbhash{$indexkey}{'timing'});
			foreach $outkey (@{$urbhash{$indexkey}{'out'}}){
				print "$outkey ";
				if(substr($outkey,0,1) eq "4"){
					$outgoing=1;
					$wval=substr($outkey,9,2); #changed
					$wval.=substr($outkey,6,2);
					$reg=substr($outkey,15,2);
					$reg.=substr($outkey,12,2);
					$breq=substr($outkey,3,2);

				} else {
					$outgoing=0;
					$wval=substr($outkey,9,2); #changed
					$wval.=substr($outkey,6,2);
					$reg=substr($outkey,15,2);
					$reg.=substr($outkey,12,2);
					$breq=substr($outkey,3,2);

				}
			}
			if($outgoing == 1){
				print ">>> ";
			} else {
				print "<<< ";
			}
			foreach $inkey (@{$urbhash{$indexkey}{'in'}}){
				print " $inkey";
			}
			print "\n";
		} else {
			print "$indexkey:  ";
			if($urbhash{$indexkey}{'remark'}[0] ne ""){
				print $urbhash{$indexkey}{'remark'}[0];
				next;
			}
			print "OUT: ";
			printf("%06d ms %06d ms ",$urbhash{sprintf("%06d",($indexkey+1))}{'timing'}-$urbhash{$indexkey}{'timing'},$urbhash{$indexkey}{'timing'});
			if($#{$urbhash{$indexkey}{'out'}} >= 0){
				printf("BULK[%05d] >>> ",$urbhash{$indexkey}{'endpoint'});
			} else {
				printf("BULK[%05d] <<< ",$urbhash{$indexkey}{'endpoint'});
			}
			foreach $outkey (@{$urbhash{$indexkey}{'out'}}){
				print "$outkey ";
			}
			foreach $inkey (@{$urbhash{$indexkey}{'in'}}){
				print "$inkey ";
			}
			print "\n";
		}
	}
}
