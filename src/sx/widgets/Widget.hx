package sx.widgets;

import sx.exceptions.NotChildException;



/**
 * Base class for widgets
 *
 */
class Widget
{
    /** Parent widget */
    public var parent (get,set) : Null<Widget>;
    private var zz_parent : Widget;
    /** Get amount of children */
    public var numChildren (get,never): Int;

    /** Display list of this widget */
    private var zz_children : Array<Widget>;



    /**
     * Cosntructor
     *
     */
    public function new () : Void
    {
        zz_children = [];
    }


    /**
     * Add `child` to display list of this widget.
     *
     * Returns added child.
     */
    public function addChild (child:Widget) : Widget
    {
        if (child.parent != null) child.parent.removeChild(child);

        zz_children.push(child);
        child.parent = this;

        return child;
    }


    /**
     * Remove `child` from display list of this widget.
     *
     * Returns removed child.
     * Returns `null` if this widget is not a parent for this `child`.
     */
    public function removeChild (child:Widget) : Null<Widget>
    {
        if (zz_children.remove(child)) {
            child.parent = null;

            return child;
        }

        return null;
    }


    /**
     * Determines if `child` is this widget itself or if `child` is in display list of this widget at any depth.
     *
     */
    public function contains (child:Widget) : Bool
    {
        if (child == this) return true;

        for (i in 0...zz_children.length) {
            if (zz_children[i].contains(child)) return true;
        }

        return false;
    }


    /**
     * Get index of a `child` in a list of children of this widget.
     *
     * @throws sx.exceptions.NotChildException If `child` is not direct child of this widget.
     */
    public function getChildIndex (child:Widget) : Int
    {
        var index = zz_children.indexOf(child);
        if (index < 0) throw new NotChildException();

        return index;
    }


    /** Getters */
    private function get_parent ()          return zz_parent;
    private function get_numChildren ()     return zz_children.length;

    /** Setters */
    private function set_parent (v)         return zz_parent = v;

}//class Widget