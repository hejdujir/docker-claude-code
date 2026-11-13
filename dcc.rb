class Dcc < Formula
  desc "Claude Code with full permissions inside an isolated Docker container"
  homepage "https://github.com/hejdujir/docker-claude-code"
  url "https://github.com/hejdujir/docker-claude-code/archive/refs/tags/v0.1.8.tar.gz"
  sha256 "f766d3de5583dd310c0618cdf8d39a2cfccb634246de11b0cb864b93a19990f0"
  license "Apache-2.0"
  head "https://github.com/hejdujir/docker-claude-code.git", branch: "main"

  def install
    bin.install "bin/dcc"
    pkgshare.install "image"
    pkgshare.install "skills"
    generate_completions_from_executable(bin/"dcc", "completion", shells: [:bash, :zsh])
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
