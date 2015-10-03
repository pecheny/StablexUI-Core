package sx.properties.abstracts;

import sx.properties.AutoSize;


/**
 * Abstract to be able to write boleans directly to `AutoSize` instances.
 *
 */
@:forward(width,height,set,onChange,either,neither,both)
abstract AbstractAutoSize (AutoSize) from AutoSize to AutoSize
{
    /** Object pool */
    static private var __pool : Array<WeakAutoSize> = [];


    /**
     * Create from boolean
     */
    @:access(sx.properties.AutoSize.weak)
    @:from static private function fromBool (v:Bool) : AbstractAutoSize
    {
        var weakAutoSize = __pool.pop();
        if (weakAutoSize == null) weakAutoSize = new WeakAutoSize();
        weakAutoSize.weak = true;
        weakAutoSize.width  = v;
        weakAutoSize.height = v;

        return weakAutoSize;
    }


}//abstract AbstractAutoSize



/**
 * For temporary instances used just to pass values to other instances
 *
 */
@:access(sx.properties.abstracts.AbstractAutoSize.__pool)
private class WeakAutoSize extends AutoSize
{

    /**
     * Constructor
     */
    public function new () : Void
    {
        super();
        onChange = null;
    }


    /**
     * Return to object pool
     */
    override public function dispose () : Void
    {
        AbstractAutoSize.__pool.push(this);
        //to prevent adding to pool multiple times
        weak = false;
    }

}//class WeakAutoSize