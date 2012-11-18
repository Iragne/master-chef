if node.lsb.codename == "lucid"

  base_ppa "pgm" do
    url "ppa:chris-lea/libpgm"
  end

  base_ppa "zeromq" do
     url "ppa:chris-lea/zeromq"
  end

end

if node.lsb.codename == "squeeze"

  add_apt_repository "squeeze-backports" do
    url "http://backports.debian.org/debian-backports"
    distrib "squeeze-backports"
    components ["main"]
  end

end

package "libzmq1"
