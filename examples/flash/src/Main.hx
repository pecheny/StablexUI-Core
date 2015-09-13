package ;

import flash.events.Event;
import flash.Lib;
import sx.backend.flash.Backend;
import sx.Sx;
import sx.widgets.Widget;


/**
 * Flash backend example
 *
 */
class Main
{

    /**
     * Entry point
     */
    static public function main () : Void
    {
        Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
        Lib.current.stage.align     = flash.display.StageAlign.TOP_LEFT;

        Sx.setBackend(new Backend());

        var root = new Widget();
        root.left.px = 200;
        root.top.px  = 200;
        root.width.px  = 100;
        root.height.px = 30;
        root.origin.set(0, 1);

        var child = root.addChild(new Widget());
        child.left.px = 50;
        child.bottom.px = -15;
        child.width.pct = 100;
        child.height.pct = 100;

        root.display == child.display;

        Sx.attach(root);

        // root.rotation = 45;
        root.scaleX = 1.5;
        // root.scaleY = Math.cos(a);

        var a = 0.;
        Lib.current.addEventListener(Event.ENTER_FRAME, function(_){
            // root.left.px += 0.1;
            // root.top.px += 0.1;

            root.rotation += 0.2;
            root.width.px = 100 + 20 * Math.sin(a);
            // root.scaleX = 1 + Math.sin(a);
            root.scaleY = 1 + 0.5 * Math.cos(a);

            child.alpha = 0.5 + 0.5 * Math.sin(2 * a);

            a += 0.02;
        });
    }

}//class Main