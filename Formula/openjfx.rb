# For `pour_bottle? do` block in main formula body below:
class XcodeCLTRequirement < Requirement
  fatal true

  satisfy(:build_env => false) do
    MacOS::CLT.installed?
  end

  def message
    <<~EOS
      This software requires the Xcode CLT in order to build.
    EOS
  end
end

class Openjfx < Formula
  desc "Open-source, next-generation Java client application platform."
  homepage "https://openjfx.io/"
  url "https://hg.openjdk.java.net/openjfx/jfx-dev/rt", :revision => "22c69e868654", :using => :hg
  sha256 "0be0d342dec0c8ca777ddce3e7ab2afa1e4145181ece4dcaec9f6385cf728fbb"
  mirror "https://hg.openjdk.java.net/openjfx/jfx-dev/rt/archive/22c69e868654.tar.gz"
  # sha256 "4f0f280dbd62104aac920b30bd299f58db6d8a87c4a2d9e96e9895d9e09f6f43"
  mirror "https://github.com/javafxports/openjdk-jfx/archive/063dd2afaa32572204fd5ca31c73330e10c57c56.tar.gz"
  # sha256 "f9856ea61178e977b07f5f2b105a7fb2c19f27824e401fe790eb37940faf1a4d"
  version "11"

  # I'm not sure if this is actually the case, but better safe than sorry…:
  pour_bottle? do
    reason "The bottle needs the Xcode CLT installed in order to run.  "
    satisfy { MacOS::CLT.installed? }
  end

  depends_on "ant"
  depends_on "cmake" # For `javafx.web`.
  depends_on "gperf" # Also for `javafx.web`.
  depends_on "gradle"

  depends_on :java => "11"
  depends_on :xcode # '>= 9.1' in the build instructions, but I'm testing on my current system
                    # first.
  depends_on XcodeCLTRequirement

  def install
    # java_home = ENV["JAVA_HOME"] # Possibly not necessary, as it may be auto-detected…?
    # ENV["JDK_HOME"] = java_home # Same here?
    # ENV.prepend_path "PATH" java_home/"bin" # I think `brew` may handle this automatically…?
    # ENV.prepend_path "PATH" Formula["gradle"].bin # Ditto for this?
    # ENV.prepend_path "PATH" Formula["ant"].bin # Same here?

    system "gradle"
    prefix.install Dir["#{buildpath}/build/modular-sdk/*"]
  end

  def caveats; <<~EOS
    In order for Java programs to find this library, you'll have to add it into their classpaths.
  EOS
  end

  test do
    # A more extensive test would build something against _all_ JavaFX modules, but this will do for
    # now.
    #
    # Adapted slightly from the example at `https://openjfx.io/openjfx-docs/#maven`:
    (testpath/"HelloFX.java").write <<~EOS
      import javafx.application.Application;
      import javafx.scene.Scene;
      import javafx.scene.control.Label;
      import javafx.stage.Stage;

      public class HelloFX extends Application {
        @Override public void start(Stage stage) {
          String javaVersion = System.getProperty("java.version");
          String javafxVersion = System.getProperty("javafx.version");
          Label l = new label("Hello, JavaFX " + javafxVersion + " running on Java " + javaVersion + ".  ";
          Scene scene = new Scene(l, 640, 400);
          stage.setScene(scene);
          stage.show();
        }

        public static void main(String[] args) {
          launch();
        }
      }
    EOS

    system "javac", "--module-path", prefix, "--add-modules=javafx.controls", testpath/"HelloFX.java"
    system "java", "--module-path", prefix, "--add-modules=javafx.controls", testpath/"HelloFX"
  end
end
