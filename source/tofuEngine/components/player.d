module tofuEngine.components.player;
import core.time:dur;
import tofuEngine;
import math.matrix;
import graphics.gui.propertyPane : NoPropertyPane, PropertyPaneButton;
import graphics.hw;

//mixin registerComponent!PlayerComponent;
//struct PlayerComponent{
//    private Timer thinkTimer;
//
//    void init(MessageContext args) {
//        thinkTimer.setTimer(dur!"seconds"(0), args);
//        change(args);
//    }
//
//    void dest(MessageContext args) {
//        thinkTimer.cancel();
//    }
//
//    void message(TimerMsg msg, MessageContext args) {
//        think(args);
//        thinkTimer.setTimer(dur!"seconds"(0), args);
//    }
//
//    void message(EditorChangeMsg msg, MessageContext args) {
//        
//    }
//
//    private void think(MessageContext args) {
//        static if(!EDITOR_ENGINE) {
//            // user input here
//        }
//    }
//
//    private void change(MessageContext args) {
//
//    }
//
//    //
//    //static if(EDITOR_ENGINE) {
//    //    import core.time:dur;
//    //    private bool selected = false;
//    //    private Timer t;
//    //
//    //    void message(EditorSelectMsg msg, MessageContext args) {
//    //        selected = msg.selected;
//    //        if(selected) 
//    //            t.setTimer(dur!"seconds"(0), args);
//    //    }
//    //
//    
//    //
//    //    @PropertyPaneButton
//    //        void SetAsCam() {
//    //            currentCam = &this;
//    //        }
//    //
//    //    @PropertyPaneButton
//    //        void ResetCam() {
//    //            currentCam = null;
//    //        }
//    //}
//}
