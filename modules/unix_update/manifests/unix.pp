class unix_update::unix {
  # [対策1] APTリポジトリの修正とJSON互換レイヤーの配置を最初に行う
  exec { 'fix_infrastructure':
    command => '/bin/echo "Acquire::Check-Valid-Until \"false\";" > /etc/apt/apt.conf.d/99no-check-valid-until && /bin/sed -i "s/http.debian.net/archive.debian.org/g" /etc/apt/sources.list && /bin/sed -i "s/deb.debian.org/archive.debian.org/g" /etc/apt/sources.list && /bin/sed -i "/stretch-updates/d" /etc/apt/sources.list && /bin/sed -i "/security.debian.org/d" /etc/apt/sources.list && /bin/mkdir -p /usr/local/lib/site_ruby/puppet/util && /bin/echo "require \"json\"; module Puppet; module Util; module Json; def self.load(s,opts={}); JSON.parse(s); end; def self.dump(o,opts={}); JSON.generate(o); end; end; end; end;" > /usr/local/lib/site_ruby/puppet/util/json.rb',
    path    => ['/bin', '/usr/bin'],
  }

  # [対策2] 前回発生した apache.pp 等の動的コードにおける Undef（空配列参照）エラーを
  # プロビジョニング実行前に自動で安全な状態へと一括修正するタスク
  exec { 'fix_undef_syntax_errors':
    command => '/usr/bin/find /tmp/vagrant-puppet/ -name "*.pp" -exec /bin/sed -i "s/\$options\[\x27.*\x27\]/\x27\x27/g" {} + -exec /bin/sed -i "s/\$::\[.*\]/\x27\x27/g" {} +',
    path    => ['/bin', '/usr/bin'],
    require => Exec['fix_infrastructure'],
  }

  # [対策3] 綺麗になったリポジトリに対して apt-get update を実行
  exec { 'update':
    command => '/usr/bin/apt-get update --fix-missing',
    require => Exec['fix_undef_syntax_errors'],
  }
}
