import com.sun.tools.attach.VirtualMachine;
import com.sun.tools.attach.VirtualMachineDescriptor;
import java.io.File;

public class OpenGhidra {
	public static void main(String[] args) throws Exception {
		Runtime.getRuntime().exec(new String[] {"open", "-a", "Ghidra"});
		while (true) {
			for (VirtualMachineDescriptor descriptor : VirtualMachine.list()) {
				if (descriptor.displayName().contains("ghidra.Ghidra")) {
					VirtualMachine vm = VirtualMachine.attach(descriptor.id());
					for (String arg : args) {
						vm.loadAgent(OpenGhidra.class.getProtectionDomain().getCodeSource().getLocation().getPath() + "/OpenGhidra.jar", new File(arg).getAbsolutePath());
					}
					vm.detach();
					return;
				}
			}
		}
	}
}
