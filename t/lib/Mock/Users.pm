use 5.22.0;

package t::lib::Mock::Users;

my %users = (
  12 => {
    permissions => {
        add_organization => 1,
        delete_organization => 1,
    },
    name => 'Billy Bob',
    organizations => {
        Vaara => 1,
        Lumme => 1,
    },
  }
);

sub _getUser {
  my ($args) = @_;

  if ($args->{userid} == 12) {
    return $users{12};
  }
  return undef;
}

sub AnsbileTorpor_checkConfigFaulty {
  my ($app, $config) = @_;

  $config = $app->config();
  $config->{ansible_home} = 't/ansible_home';
  $config->{ansible_playbook_cmd} = './ansbille_plybk';
  $config->{test_deliverables_dir} = 't/ansible_home';
}

1;

