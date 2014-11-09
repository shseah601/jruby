require 'rake/testtask'

desc "Alias for spec:ci"
task :spec => "spec:ci"

desc "Alias for test:short"
task :test => "test:short"

namespace :test do
  desc "Compile test code"
  task :compile do
    sh "javac -cp lib/jruby.jar:test/target/junit.jar -d test/target/test-classes #{Dir['spec/java_integration/fixtures/**/*.java'].to_a.join(' ')}"
  end

  short_tests = ['jruby', 'mri', 'rubicon']
  slow_tests = ['test:slow', 'test:objectspace']
  specs = ['spec:ji', 'spec:compiler', 'spec:ffi', 'spec:regression'];
  long_tests = ["test:tracing"] + short_tests + slow_tests + specs
  all_tests = long_tests.map {|test| test + ':all'}

  desc "Run the short suite: #{short_tests.inspect}"
  task :short => [:compile, *short_tests]

  desc "Run the long suite: #{long_tests.inspect}"
  task :long => [:compile, *long_tests]

  desc "Run the comprehensive suite: #{all_tests}"
  task :all => [:compile, *all_tests]

  desc "Run tests that are too slow for the main suite"
  task :slow_suites => [:compile, *slow_tests]

  task :rake_targets => long_tests
  task :extended => long_tests

  desc "Run tracing tests"
  task :tracing do
    Rake::TestTask.new('test:tracing') do |t|
      t.pattern = 'test/tracing/test_*.rb'
      t.verbose = true
      t.ruby_opts << '-J-ea'
      t.ruby_opts << '--debug'
      t.ruby_opts << '--disable-gems'
    end
  end
  
  compile_flags = {
    :default => :int,
    :int => ["-X-C"],
    :jit => ["-Xjit.threshold=0", "-J-XX:MaxPermSize=256M"],
    :aot => ["-X+C", "-J-XX:MaxPermSize=256M"],
    :all => [:int, :jit, :aot]
  }

  namespace :mri do
    mri_test_files = File.readlines('test/mri.index').grep(/^[^#]\w+/).map(&:chomp).join(' ')
    task :int do
      ruby "-X-C -r ./test/mri_test_env.rb test/mri/runner.rb -q -- #{mri_test_files}"
    end

    task :jit do
      ruby "-Xjit.threshold=0 -Xjit.background=false -r ./test/mri_test_env.rb test/mri/runner.rb -q -- #{mri_test_files}"
    end

    task :aot do
      ruby "-X+C -Xjit.background=false -r ./test/mri_test_env.rb test/mri/runner.rb -q -- #{mri_test_files}"
    end

    task all: %s[int jit aot]
  end
  task mri: 'test:mri:int'

  permute_tests(:jruby, compile_flags, 'test:compile') do |t|
    files = []
    ENV['TESTOPT'] = '-v'
    File.open('test/jruby.index') do |f|
      f.each_line.each do |line|
        filename = "test/#{line.chomp}.rb"
        next unless File.exist? filename
        files << filename
      end
    end
    t.test_files = files
    t.verbose = true
    t.ruby_opts << '-J-ea'
    t.ruby_opts << '-J-cp test:test/target/test-classes:core/target/test-classes'
  end

  permute_tests(:rubicon, compile_flags) do |t|
    files = []
    File.open('test/rubicon.index') do |f|
      f.each_line.each do |line|
        filename = "test/#{line.chomp}.rb"
        next unless File.exist? filename
        files << filename
      end
    end
    t.test_files = files
    t.verbose = true
    t.ruby_opts << '-J-ea'
    t.ruby_opts << '-X+O'
  end

  permute_tests(:slow, compile_flags) do |t|
    files = []
    File.open('test/slow.index') do |f|
      f.each_line.each do |line|
        filename = "test/#{line.chomp}.rb"
        next unless File.exist? filename
        files << filename
      end
    end
    t.test_files = files
    t.verbose = true
    t.ruby_opts << '-J-ea'
    t.ruby_opts << '-J-cp target/test-classes'
  end

  permute_tests(:objectspace, compile_flags) do |t|
    files = []
    File.open('test/objectspace.index') do |f|
      f.each_line.each do |line|
        filename = "test/#{line.chomp}.rb"
        next unless File.exist? filename
        files << filename
      end
    end
    t.test_files = files
    t.verbose = true
    t.ruby_opts << '-J-ea'
    t.ruby_opts << '-X+O'
  end
  
  def junit(options)
    cp = options[:classpath] or raise "junit tasks must have classpath"
    test = options[:test] or raise "junit tasks must have test"
    
    cmd = "#{ENV_JAVA['java.home']}/bin/java -cp #{cp.join(File::PATH_SEPARATOR)} -Djruby.compat.mode=1.8 junit.textui.TestRunner #{test}"
    
    puts cmd
    system cmd
  end
  
  namespace :junit do
    test_class_path = [
      "target/junit.jar",
      "target/livetribe-jsr223.jar",
      "target/bsf.jar",
      "target/commons-logging.jar",
      "lib/jruby.jar",
      "target/test-classes",
      "test/jruby/requireTest.jar",
      "test"
    ]
    
    desc "Run the main JUnit test suite"
    task :main => 'test:compile' do
      junit :classpath => test_class_path, :test => "org.jruby.test.MainTestSuite", :maxmemory => '512M' do
        jvmarg :line => '-ea'
      end
    end
  end
end
