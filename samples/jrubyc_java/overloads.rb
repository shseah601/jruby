require 'java'

class OverloadedClass
  java_name :run
  java_signature [String] => :void
  def run1(a); end
  
  java_name :run
  java_signature ["int"] => :void
  def run2(a); end
end

=begin
~/projects/jruby/samples/jrubyc_java ➔ jrubyc --java overloads.rb 
Compiling overloads.rb to class overloads
Generating Java class OverloadedClass to OverloadedClass.java
javac -cp /Users/headius/projects/jruby/lib/jruby.jar:. OverloadedClass.java
Note: OverloadedClass.java uses or overrides a deprecated API.
Note: Recompile with -Xlint:deprecation for details.

~/projects/jruby/samples/jrubyc_java ➔ cat OverloadedClass.java 
import org.jruby.Ruby;
import org.jruby.RubyObject;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.javasupport.JavaUtil;
import org.jruby.RubyClass;


public class OverloadedClass extends RubyObject  {
  private static final Ruby __ruby__ = Ruby.getGlobalRuntime();
  private static final RubyClass __metaclass__;
  static {
    __ruby__.getLoadService().lockAndRequire("overloads.rb");
    RubyClass metaclass = __ruby__.getClass("OverloadedClass");
    metaclass.setClassAllocator(OverloadedClass.class);
    if (metaclass == null) throw new NoClassDefFoundError("Could not load Ruby class: OverloadedClass");
        __metaclass__ = metaclass;
  }
  public OverloadedClass() {
    super(__ruby__, __metaclass__);
  }

  public void run(String a) {
    IRubyObject ruby_a = JavaUtil.convertJavaToRuby(__ruby__, a);
    IRubyObject ruby_result = RuntimeHelpers.invoke(__ruby__.getCurrentContext(), this, "run1" ,ruby_a);
    
  }



  public void run(int a) {
    IRubyObject ruby_a = JavaUtil.convertJavaToRuby(__ruby__, a);
    IRubyObject ruby_result = RuntimeHelpers.invoke(__ruby__.getCurrentContext(), this, "run2" ,ruby_a);
    
  }

}
=end