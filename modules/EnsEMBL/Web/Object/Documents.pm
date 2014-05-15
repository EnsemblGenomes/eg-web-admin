package EnsEMBL::Web::Object::Documents;

=head1 NAME

EnsEMBL::Web::Object::Documents - file management for the EBI Admin plugin

=head1 METHODS

=cut

use strict;
use File::Basename;
use File::Copy;
use Cvs;
 
sub open {
  my ($self,$pathname,$filename,$action)=@_;
  my $plugins = $self->available_plugins;
  my $path = $plugins->{$pathname} . "/$filename";
  $self->{'_pathname'} = $pathname;
  $self->{'_filename'} = $filename;
  $self->{'_path'} = $path; #full path available!
  my $content = '';
  if($filename !~ /png$|jpg$/i){
    open FILE, "<$path";
    $content = join('', map {$_} <FILE>);
    close FILE;
  }
  $self->{'_lock'} = "$path.lock";
  $self->{'_content'} = $content;
  $self->{'_debug'} = undef;
  $self->{'_config'}=$self->get_config($pathname);
  return 1;
}

sub get_config{
  my ($self,$pathname)=@_;
  if($pathname){
    my ($cfgkey) = split('_',$pathname);
    return $SiteDefs::CONTENT_CONFIG->{$cfgkey} if $SiteDefs::CONTENT_CONFIG;
  }
  return $SiteDefs::CONTENT_CONFIG;
}

sub lock {
  my ($self,$cmd,$msg)=@_;
  my $lock = $self->{'_lock'};
  if($cmd eq 'status'){
    return $self->fileio($lock,'r');
  }
  if($cmd =~ /^lock$|^steal$/i  ){
    return $self->fileio($lock,'w',$msg);
  }
  if($cmd =~ /^unlock$/i  ){
    unlink $lock;
    return "unlocked";
  }
}

=head2 fileio

  Arg [1]   : $filename (full path)
  Arg [2]   : mode, read or write, 'r' or 'w'
  Arg [3]   : $$content (pointer to source/destination string)

=cut

sub fileio{
  my ($self,$file,$io,$msg)=@_;
  my $content = $msg;
  if (ref $msg){
    $content = $$msg;
  }
  if( -e $file && $io eq 'r'){
    open(FH, "< $file") or return 0;
    $content = <FH>;
    close FH;
  }
  if($io eq 'w'){
    open(FH, "> $file") or return 0;
    print FH $content;
    close FH;
  }
  if (ref $msg){
    $$msg = $content;
    return 1;
  }
  return $content;
}

sub lock_askpass{
  my ($self,$lock)=@_;
  my $file=$SiteDefs::SSH_ASKPASS . ".lock";
  #create
  if(! -e $file){
    open(FH, ">$file");
    close FH;
    chmod  0100, $file;
  }
  if( $lock ){
    if(-x $file){
      chmod  0000, $file;
      return 1;#success
    }
    else{return 0;} #fail - already locked
  }
  else{chmod  0100, $file;}#unlock, no matter what
  return 1;
}
   
  
sub rewrite_askpass{
  my($self,$password)=@_;
  my $script = qq{#!/bin/sh
DISPLAY=:0
export DISPLAY
echo \$1|grep -iq password && echo $password && exit
echo \$1|grep -iq passphrase && echo && exit
echo yes
};
  open FILE, "+>", $SiteDefs::SSH_ASKPASS or die $!;
  print FILE $script;
  close FILE;
  chmod  0700, $SiteDefs::SSH_ASKPASS;
}

sub cvs {
  my $self = shift;
  my %params = @_;
  my($cmd,$comment,$username,$password,$images,$tag,$cvs_options,$file) = ($params{'action'}, $params{'comment'}, $params{'username'}, $params{'password'}, $params{'images'}, $params{'tag'},$params{'cvs_options'},$params{'file'}); 
 #if($tag =~ /^HEAD$/i){$tag=undef}
  my $overwrite = (grep /^overwrite$/i, @$cvs_options) ? 1 : undef;
  my $force = (grep /^force$/i, @$cvs_options) ? 1 : undef;
  my $sandbox = $SiteDefs::ENSEMBL_SERVERROOT;
  my @files;
  $file ||= $self->path;
  $file =~ s/^$sandbox//; # remove sandbox path
  $file =~ s/^[\/]+//; # remove leading slash
  if( ! ref $images ){ $images = [ $images ]; }
  ### resolve EG::Plugin/image paths
  for my $img (@$images){
    my ($plugin,@imgpath)=split('/',$img);
    my $root = $SiteDefs::CONTENT_CONFIG->{$plugin}->{'root'};
    $root =~ s/$sandbox\///;
    unshift(@imgpath,$root);
    push(@files, join("/",@imgpath));
  }
  unshift(@files,$file);
  my $msg = "";
  my $cvs;
  my $pubcvsroot = ':pserver:cvsuser@cvs.sanger.ac.uk/cvsroot/ensembl';
  my ($public) = Cvs->new( 
    $sandbox,
    cvsroot => $pubcvsroot,
    password => 'cvs',
    debug => $self->{'_debug'},
  ) or die $Cvs::ERROR;
  if($username && $password){
    ($cvs) = Cvs->new( 
      $sandbox,
      cvsroot => sprintf(':ext:%s@cvs.sanger.ac.uk/cvsroot/CVSmaster',$username),
      password => $password,
      debug => $self->{'_debug'},
    ) or die $Cvs::ERROR;
  }
  else{
    $cvs = $public;
    if($cmd =~ /^commit$/i){$msg.="Enter username and password to commit changes. ";}
  }
  my ($file)=@files;
  my $error = "";
  my $status =  $cvs->status($file);
  if($cmd=~/^info$/i){
    return $status;
  }
  if($cmd=~/^commit$/i){
    for my $target (@files){
      $status =  $cvs->status($target);
      my $sticky_tag = $status->success ? $status->sticky_tag : "";
      $sticky_tag =~ s/\s.*$/\1/;
      #eval in order to remove lock if commit fails
      eval{
        if(! $self->lock_askpass(1)){return "Failed: this service is locked for CVS changes. Please try again.";}
        $self->rewrite_askpass($password);
        #check to see if we need to add it
        if(!$status->success || $status->status() =~ /Unknown/i){
          chdir($sandbox) or warn "cannot chdir $sandbox: $!";
          system("cvs -q -d $pubcvsroot add $target 1\>/dev/null 2\>\&1");
          warn "cvs add $target system exit code $?\n" if $self->{'_debug'};
        }
        my $backup = $target . ".backup";
        $tag = 'HEAD' unless $tag;
        if($tag){ # tag is set - make a backup, check out the target revision, copy backup to target 
          chdir($sandbox) or warn "cannot chdir $sandbox: $!";
          if(copy($target,$backup)){
            my %_modified_params = @_;
            $_modified_params{'action'}='update';
            $_modified_params{'cvs_options'}=['overwrite'];
            delete $_modified_params{'tag'} if ($tag =~ /^HEAD$/i);
            my $update_result = $self->cvs(%_modified_params);
            $msg .= $update_result;
            copy($backup,$target);
          }
          else {
            $msg .= "Error: cannot create backup.";
          }
        }
        my $result = $cvs->commit({recursive=>0,message=>$comment,force=>$force},$target);
        $msg .= sprintf("%s: %s; ",$target,$result->success ? "New rev " . $result->new_revision : $result->error ? "Commit failed, " . $result->error : "");
        if($tag){
          # restore previously selected version AND the backup
          my %_modified_params = @_;
          $_modified_params{'action'}='update';
          $_modified_params{'tag'}=$sticky_tag || undef;
          $_modified_params{'cvs_options'}=['overwrite'];
          $msg .= $self->cvs(%_modified_params);
          move($backup,$target);
        }
        $self->rewrite_askpass();
        $self->lock_askpass(0);
      };
      if($@){
        $msg .= "CVS commit failure: $@\n";
        $self->lock_askpass(0);
      }
    }
    $status = $public->status($file);
  }
  elsif($cmd=~/^update$/i){
    for my $target (@files){
      my $result=$public->update($target,{'overwrite_local_modified'=>$overwrite,'revision'=>$tag,'reset'=> $tag ? undef : 1 });
      my @update_status; 
      for my $st (qw/updated patched added removed modified conflict unknown gone/ ){
        push(@update_status,$st) if( @{$result->{$st}} > 0 );
      }
      unshift(@update_status,"Failed to update (try ticking the Overwrite option!)") unless ( (! @update_status) || grep(/^updated$/,@update_status) );
      $msg .= sprintf("%s: %s. ",$target, $result->success ? join(", ",@update_status): $result->error ? "Update failed, " . $result->error : "");
    }
    $status = $public->status($file);
  }
  elsif($cmd=~/^status$/i){
    $status = $public->status($file);
  }
  $self->{'sticky_tag'} = $status->sticky_tag if $status->success;
  @{$self->{'tags'}} = reverse $status->tags if $status->success;
  unshift (@{$self->{'tags'}},'HEAD');
  $msg .= $status->success ? 
    sprintf("CVS status: %s; rev %s; \n", $status->status,$status->repository_revision)
  : sprintf("CVS error: %s\n",$status->error);
  return $msg;
}

sub available_plugins {
  my ($self,$image_mode) = @_;
  my %plugins;
  for my $pathname ( keys %$SiteDefs::CONTENT_CONFIG ){
    my $cfg = $SiteDefs::CONTENT_CONFIG->{$pathname};
    next unless $cfg;
    if($image_mode){
      for my $subpath (@{$cfg->{'images'}}){
        my $subpath_name = $pathname . "/" . $subpath;
        $subpath_name =~ s/\//_/g;
        $plugins{$subpath_name}=$cfg->{'root'} . "/" . $subpath;
      }
    }
    else{
      for my $subpath (@{$cfg->{'htdocs'}}){
          
        my $subpath_name = $pathname . "/" . $subpath;
        $subpath_name =~ s/\//_/g;
        if($cfg->{$subpath}){
          $plugins{$subpath_name}=$cfg->{$subpath};
        }
        else{
          $plugins{$subpath_name}=$cfg->{'root'} . "/" . $subpath;
        }
      }
    }
  }
  $self->{'_plugins'} = \%plugins;
  return \%plugins;
}

sub uploadable_plugins{
  my $self=shift;
  return $self->{'_uploadable_plugins'} if(exists $self->{'_uploadable_plugins'});
  my @dirs = ();
  my $plugins = $self->available_plugins;
  foreach my $pathname ( keys %$plugins ){
    my $path=$plugins->{$pathname};
    my @image_dirs;
    if(my $cat = $self->get_config($pathname)){
      @image_dirs = map { $cat->{'root'} ."/$_" } @{$cat->{'images'}};
    }
    else{
      if($path =~ /^(.+htdocs)\/ssi$/){
        $path = "$1/img/species";
      }
      @image_dirs = ($path);
    }
    for $path (@image_dirs){
      push(@dirs,$pathname) if (-d $path);
    }
  }
  return \@dirs;
}

sub viewcvs_url {
  my ($self,$pathname,$filename)=@_;
  my @path = split(/_/,$pathname);
  $pathname = shift @path;
  my $subpath = join('/',@path);
  my $cfg = $self->get_config($pathname);
  my $localpath = sprintf("%s/%s",$cfg->{'root'},$subpath);
  $localpath .= "/$filename" if $filename;
  $localpath =~ s/$SiteDefs::ENSEMBL_SERVERROOT\///;
  return sprintf("http://cvs.sanger.ac.uk/cgi-bin/viewvc.cgi/%s?root=ensembl",$localpath,$filename);
}

sub get_images {
  #Replacement for plugin_images;
  my ($self,$pathname,$selected_path)=@_;
  my ($plugin)= split ('_',$pathname);
  my $config = $SiteDefs::CONTENT_CONFIG->{$plugin};
  return unless $config;
  my %images;
  my @paths = $selected_path ? ($selected_path) : @{$config->{'images'}};
  for my $imgdir (@paths){
    my $path = sprintf("%s/%s",$config->{'root'},$imgdir);
    opendir(my $dh, $path) or next;
    my @files = grep { /^[^.]/ && /\.jpg$|\.png$/i && -f "$path/$_" } readdir($dh);
    closedir $dh;
    $images{$imgdir}=\@files;
  }
  return \%images;
}
    

sub plugin_images{
  my ($self,$pathname)=@_;
  $pathname ||= $self->pathname;
  my %paths; # return hash of { /url/path => filename }
  my @image_dirs;
  my $plugins = $self->available_plugins;
  if(my $path = $plugins->{$pathname}){
    if(my $cat = $self->get_config($pathname)){
      @image_dirs = map { $cat->{'root'} ."/$_" } @{$cat->{'images'}};
    }
    else{
      $path =~ s/\/htdocs\/.*$/\/htdocs\/img\/species/;
      @image_dirs = ($path);
    }
    for $path (@image_dirs){
      opendir(my $dh, $path) or return {};
      my @files = grep { /^[^.]/ && /\.jpg$|\.png$/i && -f "$path/$_" } readdir($dh);
      closedir $dh;
      map { $path =~ s/$_// } @SiteDefs::ENSEMBL_HTDOCS_DIRS;
      $paths{$path} = \@files;
    }
  }
  return \%paths;
}

sub abs_root{
  # get the root directory of the plugin htdocs
  my ($self,$pathname) = @_;
 #$pathname =~ s/_/::/;
  my $cat = $self->get_config($pathname,1);
  if($cat){
    return $cat->{'root'};
  }
  else{
    #it is an ordinary eg-plugin
    return $self->htdocs_path($pathname);
  }
}

sub img_path{
  my ($self,$path) = @_;
  $path ||= $self->htdocs_path;
  $path =~ s/\/htdocs\/.*$/\/htdocs\/img\/species/;
  return $path;
}

sub pathname{
  my ($self,$pathname)=@_;
  $self->{'_pathname'}=$pathname if $pathname;
  return $self->{'_pathname'};
}
sub path {
  my $self=shift;
  return $self->{'_path'};
}
sub local_uri {
  my ($self)=@_;
  my $webpath = $self->path;
  map { $webpath =~ s/$_// } @SiteDefs::ENSEMBL_HTDOCS_DIRS;
  return $webpath;
}
sub filename{
  my ($self,$filename)=@_;
  $self->{'_filename'}=$filename if $filename;
  return $self->{'_filename'};
}
sub content {
  my ($self,$newcontent)=@_;
  if($newcontent){
    $self->{'_content'}=$newcontent;
    return 1;
  }
  return $self->{'_content'}
}

sub write {
  my $self=shift;
  my $path = $self->path;
  my $content = $self->content;
  open FILE, ">$path" or return 0;
  print FILE $content;
  close FILE;
  return 1;
}

1;
