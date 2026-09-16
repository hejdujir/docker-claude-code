class Dcc < Formula
  desc "Claude Code with full permissions inside an isolated Docker container"
  homepage "https://github.com/hejdujir/docker-claude-code"
  url "https://github.com/hejdujir/docker-claude-code/archive/refs/tags/v0.1.4.tar.gz"
  sha256 "d2610e463d789a2f186d1e863c6ca11b7b6bcb12e7b8866b09d837ddf88eb146"
  license "Apache-2.0"
  head "https://github.com/hejdujir/docker-claude-code.git", branch: "main"

  def install
    bin.install "bin/dcc"
    pkgshare.install "image"
    pkgshare.install "skills"
  end

  def caveats
    <<~EOS
      Requires a running Docker (Docker Desktop, Colima, OrbStack, ...).

      Start in the directory that should be the home for Claude Code:
        mkdir -p ~/dev/claude && cd ~/dev/claude
        dcc create
    EOS
  end

  test do
    assert_match "dcc #{version}", shell_output("#{bin}/dcc --version")
  end
end
