import ghidra.app.services.ProgramManager;
import ghidra.formats.gfilesystem.FileSystemService;
import ghidra.framework.main.AppInfo;
import ghidra.plugin.importer.ImporterUtilities;
import java.awt.Frame;
import java.awt.Menu;
import java.awt.MenuItem;
import java.io.File;
import java.util.Timer;
import java.util.TimerTask;

public class OpenGhidraAgent {
	private static boolean checkMenuForReadiness(MenuItem menuItem) {
		if (menuItem.getLabel().contains("Import File") && menuItem.isEnabled()) {
			return true;
		} else if (menuItem instanceof Menu) {
			var menu = (Menu)menuItem;
			for (int i = 0; i < menu.getItemCount(); ++i) {
				if (checkMenuForReadiness(menu.getItem(i))) {
					return true;
				}
			}
		}
		return false;
	}

	public static void agentmain(String agentArgs) {
		Timer timer = new Timer();
		timer.schedule(new TimerTask() {
			@Override
			public void run() {
				for (var frame : Frame.getFrames()) {
					var menuBar = frame.getMenuBar();
					if (menuBar == null) {
						continue;
					}
					for (int i = 0; i < menuBar.getMenuCount(); ++i) {
						if (checkMenuForReadiness(menuBar.getMenu(i))) {
							var file = new File(agentArgs);
							var tool = AppInfo.getFrontEndTool();
							var manager = tool.getService(ProgramManager.class);
							var fsrl = FileSystemService.getInstance().getLocalFSRL(file);
							var folder = AppInfo.getActiveProject().getProjectData().getRootFolder();
							ImporterUtilities.showImportDialog(tool, manager, fsrl, folder, null);
							timer.cancel();
							return;
						}
					}
				}
			}
		}, 0, 100);
	}
}
