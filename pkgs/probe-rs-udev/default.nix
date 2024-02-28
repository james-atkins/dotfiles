{ runCommand }:

runCommand "probe-rs-udev" {} ''
  mkdir -p $out/lib/udev/rules.d
  cp ${./69-probe-rs.rules} $out/lib/udev/rules.d/69-probe-rs.rules
''
