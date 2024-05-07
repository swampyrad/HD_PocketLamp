class HDPocketLamp:HDWeapon{
    bool LAMP_ON;//apply directly to the lamp

	default{
		-hdweapon.droptranslation
		+inventory.invbar
		
		inventory.icon "PLMPA0";
        weapon.selectionorder 101;
	///	weapon.slotnumber 8;
	//	weapon.slotpriority 8;
		scale 0.3;
		tag "UAC Pocket Lamp";
		hdweapon.refid "pkl";
	}

    override bool Use(bool pickup) {
		if (owner.player.cmd.buttons & BT_USE) {
			return super.Use(pickup);
		}
		
		A_StartSound("weapons/plasswitch",8);

        if(LAMP_ON==true)
                {LAMP_ON=false;
                 A_WeaponMessage("Lamp turned off.",50);
                 owner.A_RemoveLight("HDPocketLampLight");
                }
        else if(LAMP_ON==false)
                {LAMP_ON=true;
                 A_WeaponMessage("Lamp turned on.",50);
                }
		return false;
	}

    override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}

    override string PickupMessage() {
	    String pickupmessage = Stringtable.Localize("You got a pocket lamp!"); 
	    return pickupmessage;
	}

    override double weaponbulk(){
		return 20;
	}

    override string,double getpickupsprite(bool usespare){
		return "PLMPA0",0.6;
	}
	
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(!hdw.weaponstatus[1])sb.drawstring(
			sb.mamountfont,"00000",(-16,-9),sb.DI_TEXT_ALIGN_RIGHT|
			sb.DI_TRANSLATABLE|sb.DI_SCREEN_CENTER_BOTTOM,
			Font.CR_DARKGRAY
		);else if(hdw.weaponstatus[1]>0)sb.drawwepnum(hdw.weaponstatus[1],20);
		}

    override string gethelptext(){
		return
		WEPHELP_FIRE.."  Turn on/off \n";
	}
	
	override void tick(){
		super.tick();
		let cellcharge = weaponstatus[TBS_BATTERY];
		if(cellcharge>0&&LAMP_ON){
		    if(!random(0,1950)&&cellcharge>1)weaponstatus[TBS_BATTERY]--;
		    //drain battery when turned on
		    
		    if(owner){//remove light from pickup and attach to player
		    A_RemoveLight("HDPocketLamplight");
		    owner.A_AttachLight("HDPocketLampLight",
		                        DynamicLight.PointLight,
		                        0xffffaf,
		                        cellcharge*8+32,
		                        cellcharge*8+32,
		                        0,
		                        (0,0,owner.height*0.8)
		                        );
		    }
		    //attach to pickup if dropped
		    else A_AttachLight("HDPocketLampLight",
		                        DynamicLight.PointLight,
		                        0xffffaf,
		                        cellcharge*8+32,
		                        cellcharge*8+32);
		    }
		    if(!random(0,350)&&cellcharge<20&&!LAMP_ON)
		        weaponstatus[TBS_BATTERY]++;
		    //recharge battery when turned off
	}
    
    override inventory CreateTossable(int amt){
		let onr=hdplayerpawn(owner);
		bool throw=(
			onr
			&&onr.player
			&&onr.player.cmd.buttons&BT_ZOOM
		);
		bool isreadyweapon=onr&&onr.player&&onr.player.readyweapon==self;
		if(!isreadyweapon)throw=false;
		let thrown=super.createtossable(amt);
		if(!thrown)return null;
		let newwep=GetSpareWeapon(onr,doselect:isreadyweapon);
		hdweapon(thrown).bjustchucked=true;
		thrown.target=onr;
		thrown.lastenemy=onr;
		if(throw){
			thrown.bmissile=true;
			thrown.bBOUNCEONWALLS=true;
			thrown.bBOUNCEONFLOORS=true;
			thrown.bALLOWBOUNCEONACTORS=true;
			thrown.bBOUNCEAUTOOFF=true;
		}else{
			thrown.bmissile=false;
			thrown.bBOUNCEONWALLS=false;
			thrown.bBOUNCEONFLOORS=false;
			thrown.bALLOWBOUNCEONACTORS=false;
			thrown.bBOUNCEAUTOOFF=false;
		}
		onr.A_RemoveLight("HDPocketLampLight");
		return thrown;
	}
	//an override is needed because DropInventory will undo anything done in CreateTossable
	double throwvel;
	override void OnDrop(Actor dropper){
	    dropper.A_RemoveLight("HDPocketLampLight");
		if(bjustchucked&&target){
			double cp=cos(target.pitch);
			if(bmissile){
				vel=target.vel+
					(cp*(cos(target.angle),sin(target.angle)),-sin(target.pitch))
					*min(20,800/weaponbulk())
					*(hdplayerpawn(target)?hdplayerpawn(target).strength:1.)
				;
			}else vel=target.vel+(cp*(cos(target.angle),sin(target.angle)),-sin(target.pitch))*4;
			throwvel=vel dot vel;
			bjustchucked=false;
		}

		//copypasted from HDPickup
		if(dropper){
			setz(dropper.pos.z+dropper.height*0.8);
			if(!bmissile){
				double dp=max(dropper.pitch-6,-90);
				vel=dropper.vel+(
					cos(dp)*(cos(dropper.angle),sin(dropper.angle)),
					-sin(dp)
				)*3;
			}
			HDBackpack.ForceUpdate(dropper);
		}
	}
		
	override void initializewepstats(bool idfa){
		weaponstatus[TBS_BATTERY]=20;
		LAMP_ON=false;
	}

  states{
  select0:
	TNT1 A 0 A_TakeInventory("NulledWeapon");
	#### A 0;
	---- A 1 A_Raise();
	---- A 1 A_Raise(30);
	---- A 1 A_Raise(30);
	---- A 1 A_Raise(24);
	---- A 1 A_Raise(18);
	wait;

  deselect0:
	TNT1  A 0;
	---- AAA 1 A_Lower();
	---- A 1 A_Lower(18);
	---- A 1 A_Lower(24);
	---- A 1 A_Lower(30);
	wait;

  ready:
	TNT1  A 0 ;
	#### # 1 A_WeaponReady(WRF_ALL);
	goto readyend;

 
 fire://toggle power switch
    #### A 1 {
             if(invoker.LAMP_ON==false)
                invoker.LAMP_ON=true;
        else if(invoker.LAMP_ON==true)
                invoker.LAMP_ON=false;
            
            A_StartSound("weapons/plasswitch",8);
            if(invoker.LAMP_ON)setweaponstate("turnon");
            if(!invoker.LAMP_ON)setweaponstate("turnoff");
            }
  goto nope;
  
  turnon:
    ---- A 0 {  A_WeaponMessage("Lamp turned on.",50);
                A_Overlay(2,"light_on");
                }
    goto nope;
  
  turnoff:
    ----  A 0 { A_WeaponMessage("Lamp turned off.",50); 
                A_Overlay(2,"light_off");
                }
    goto nope;
 
 light_on:
    TNT1 A 1;
    TNT1 A 0 {  A_RemoveLight("HDPocketLampLight");
                if(invoker.LAMP_ON)A_Overlay(2,"light_on");
                if(!invoker.LAMP_ON||invoker.weaponstatus[TBS_BATTERY]<=0)
                A_Overlay(2,"light_off");
                }
        stop;
  light_off:
        TNT1 A 0 {  invoker.A_RemoveLight("HDPocketLampLight");
                    if(self)self.A_RemoveLight("HDPocketLampLight");
                    }
        stop;
    
  altfire:
  unload:
  reload:
  altreload:
    goto nope;
    
  spawn:
		PLMP A -1;
		stop;
	
	}
}
