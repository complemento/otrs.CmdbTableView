# --
# Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentITSMConfigItemAjaxUpdate;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

#our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # my param object
    my $ParamObject 		 = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $ConfigItemObject     = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my $ConfigObject         = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject         = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my $ConfigItemID = $ParamObject->GetParam( Param => 'ConfigItemID' ) || 0;
    my $Changed      = $ParamObject->GetParam( Param => 'Changed' ) 	 || '';
    my $NewValue     = $ParamObject->GetParam( Param => $Changed ) 	     || '';

	
    if ( $Self->{Subaction} eq 'edit' ) {
            my $ConfigItem = $ConfigItemObject->VersionGet(
                ConfigItemID => $ConfigItemID,
                XMLDataGet   => 1,
            );

			my $hk;

			if($Changed =~ /::/ ){
				my $key = $Changed;
				my @keys = split '::', $key;

				my $i=0;
				for my $k (@keys){
					$i++;
					if($i % 2){
						$hk.="->{$k}";
					} else {
						$hk.="->[$k]";
					}
				}
				$hk='$ConfigItem->{XMLData}->[1]->{Version}->[1]'.$hk.'->{Content} = $NewValue;';
			} else {
#				if ($Changed eq 'CurDeplState') {
#					$Changed = 'DeplStateID';
#				}
				$hk='$ConfigItem->{\''.$Changed.'\'} = $NewValue;';
			}

			eval($hk);

			# add a new version with the nw incident state
			my $VersionID = $Kernel::OM->Get("Kernel::System::ITSMConfigItem")->VersionAdd(
				%{$ConfigItem},

				UserID => $Self->{UserID},
			);

			if(!$VersionID){
				# Se erro
				return $LayoutObject->Attachment(
					ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
					Content     => '',
					Type        => 'inline',
					NoCache     => 1,
				);
			}

		# Se sucesso	
		my %Response = (
			Successful => 'ok'
		);
		my $JSON = $LayoutObject->JSONEncode(
		    Data => \%Response,
		);
		return $LayoutObject->Attachment(
		    ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
		    Content     => $JSON,
		    Type        => 'inline',
		    NoCache     => 1,
		);
    }
}

1;
