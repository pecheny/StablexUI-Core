package sx.exceptions;

import haxe.Exception;
import haxe.PosInfos;


/**
 * Base class for StablexUI exceptions
 *
 */
class SxException extends Exception
{

    /**
     * Constructor
     *
     */
    public function new (msg:String = '', pos:PosInfos = null) : Void
    {
        super(msg);
//        truncateStack(1);
    }

}//class SxException