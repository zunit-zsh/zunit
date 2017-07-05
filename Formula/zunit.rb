class Zunit < Formula
  desc "Powerful testing framework for ZSH projects"
  homepage "https://zunit.xyz"
  url "https://github.com/molovo/zunit/archive/v0.7.0.tar.gz"
  sha256 "4833b869baad8d396d5436faa0ea86b2caec8bbb0022495c5c17957ce4eb6ff1"
  head "https://github.com/molovo/zunit.git", :branch => "next"

  devel do
    url "https://github.com/molovo/zunit/archive/v0.8.0-alpha.tar.gz"
    version "0.8.0-alpha"
    sha256 "5d3e476d74f563e5b13ce67f251081c5f36c91eadae8f8f745a512f5557cede1"
  end

  bottle :unneeded
  depends_on "revolver" => :run

  resource "color" do
    url "https://github.com/molovo/color.git"
    sha256 "9b6787e3503d4923d6aafa1b52f62efce68000cfdd8d52b313ebc36cb40de2a2"
  end

  def install
    resource("color").stage do
      mv "color.zsh", "color"
      lib.install "color"
      bin.install_symlink "#{lib}/color"
    end

    system "./build.zsh"
    bin.install "zunit"
    zsh_completion.install "zunit.zsh-completion" => "_zunit"
  end

  test do
    assert_equal version.to_s, shell_output("#{bin}/zunit -v")
  end
end
