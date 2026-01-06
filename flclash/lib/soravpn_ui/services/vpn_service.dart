import 'dart:async';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/soravpn_ui/models/node_group.dart';
import 'package:fl_clash/soravpn_ui/services/subscribe_service.dart';
import 'package:fl_clash/soravpn_ui/models/proxy_mode.dart';
import 'package:fl_clash/enum/enum.dart'; // Import Mode enum

/// VPN Service Adapter for FlClash
/// Bridges SoraVPN UI calls to FlClash CoreController
class VpnService {
  static bool get isConnected => globalState.isStart;
  static VpnNode? get currentNode => null; // TODO: Map back from FlClash state
  static String? get lastError => null; // TODO: Get from FlClash log
  /// Get current proxy mode from FlClash config
  static ProxyMode get proxyMode {
    try {
      final mode = globalState.config.patchClashConfig.mode;
      switch (mode) {
        case Mode.rule:
          return ProxyMode.smart;
        case Mode.global:
          return ProxyMode.global;
        case Mode.direct:
          return ProxyMode.smart; // Treat direct as smart for UI purposes
      }
    } catch (e) {
      print('[VpnService] Error getting proxy mode: $e');
      return ProxyMode.smart;
    }
  }

  static void setProxyMode(ProxyMode mode) {
    Mode targetMode;
    switch (mode) {
      case ProxyMode.smart:
        targetMode = Mode.rule;
        break;
      case ProxyMode.global:
        targetMode = Mode.global;
        break;
    }
    
    // Call FlClash controller to switch mode
    globalState.appController.changeMode(targetMode);
    print('[VpnService] Switched FlClash mode to: ${targetMode.name}');
  }
  
  // Group Selections - Map to FlClash's proxy group selection
  static Future<void> loadGroupSelections() async {
    // FlClash manages selections internally, nothing to load
  }
  
  /// Save a routing group selection using FlClash's changeProxy API
  static Future<void> saveGroupSelection(String groupTag, String nodeTag) async {
    try {
      await coreController.changeProxy(ChangeProxyParams(
        groupName: groupTag,
        proxyName: nodeTag,
      ));
      print('[VpnService] Changed proxy selection: $groupTag -> $nodeTag');
      
      // Update groups to reflect the change
      await globalState.appController.updateGroups();
    } catch (e) {
      print('[VpnService] Failed to change proxy selection: $e');
    }
  }
  
  /// Get current selection for a group from FlClash's groups state
  static String? getSelectionForGroup(String groupTag) {
    try {
      final groups = globalState.appController.getCurrentGroups();
      for (final group in groups) {
        if (group.name == groupTag) {
          return group.now; // 'now' is the currently selected proxy in this group
        }
      }
    } catch (e) {
      print('[VpnService] Failed to get selection for group $groupTag: $e');
    }
    return null;
  }

  /// CONNECT
  /// Triggers FlClash start sequence using proper updateStatus method
  /// This ensures runTimeProvider updates and ProxyManager enables system proxy
  static Future<bool> connect(VpnNode node) async {
    print('[VpnService] Bridge: Requesting FlClash Start via updateStatus...');
    try {
        // Optimize: Only sync if profile is missing or inactive
        final currentProfile = globalState.config.currentProfile;
        final hasGroups = globalState.appController.getCurrentGroups().isNotEmpty;
        final isSoraProfile = currentProfile?.id == 'soravpn_main';
        
        if (!isSoraProfile || !hasGroups) {
          print('[VpnService] Profile missing or inactive, syncing...');
          await SubscribeService.syncToFlClash();
        } else {
          print('[VpnService] Profile "soravpn_main" active with groups, skipping sync for speed.');
        }
        
        // Use updateStatus(true) which properly:
        // 1. Calls tryStartCore() to initialize core
        // 2. Calls handleStart with updateRunTime and updateTraffic tasks
        // 3. This updates runTimeProvider which triggers ProxyManager
        // 4. ProxyManager then calls proxy.startProxy() to set system proxy
        await globalState.appController.updateStatus(true);
        
        // Attempt to select the specific node
        try {
           // Lray template uses "节点选择" as the main selector group
           // Also try common group names from clash.tpl
           final groupNames = ['节点选择', '🚀 Proxy', 'Proxy', 'GLOBAL'];
           for (final groupName in groupNames) {
             try {
               await coreController.changeProxy(ChangeProxyParams(
                   groupName: groupName, 
                   proxyName: node.name
               ));
               print('[VpnService] Selected node ${node.name} in group $groupName');
               break;
             } catch (_) {
               // Try next group name
             }
           }
        } catch (e) {
           print('[VpnService] Note: Failed to set proxy selection: $e');
        }
        
        return true;
    } catch (e) {
        print('[VpnService] Bridge Error: $e');
        return false;
    }
  }

  /// DISCONNECT
  /// Uses updateStatus(false) to properly stop core and clear system proxy
  static Future<void> disconnect() async {
    print('[VpnService] Bridge: Requesting FlClash Stop via updateStatus...');
    await globalState.appController.updateStatus(false);
  }
}
