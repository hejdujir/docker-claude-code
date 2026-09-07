class Dcc < Formula
  desc "Claude Code with full permissions inside an isolated Docker container"
  homepage "https://github.com/hejdujir/docker-claude-code"
  url "https://github.com/hejdujir/docker-claude-code/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "0fb36435f9fe06b069fdc17a2e598bebc0c1e04c5fba8a1214e7ed0748cca001"
  license "Apache-2.0"
  head "https://github.com/hejdujir/docker-claude-code.git", branch: "main"

  def install
    bin.install "bin/dcc"
    pkgshare.install "image"
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
