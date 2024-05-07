version "4.8"

#include "zscript/item_pocketlamp.zs"

class PocketLamp_Spawner : EventHandler{

override void CheckReplacement( ReplaceEvent PocketLamp ){

 switch ( PocketLamp.Replacee.GetClassName() ) {
    case 'Infrared'   :   if(!random(0,3))PocketLamp.Replacement = "HDPocketLamp";
        break;
    }
    PocketLamp.IsFinal = false;
  }
}
