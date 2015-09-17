package sx.widgets;

import sx.backend.Backend;
import sx.exceptions.NotChildException;
import sx.exceptions.OutOfBoundsException;
import sx.geom.Matrix;
import sx.geom.Orientation;
import sx.geom.Unit;
import sx.properties.Coordinate;
import sx.properties.displaylist.ArrayDisplayList;
import sx.properties.Origin;
import sx.properties.Size;
import sx.signals.MoveSignal;
import sx.signals.ResizeSignal;
import sx.skins.Skin;
import sx.Sx;

using sx.tools.WidgetTools;


/**
 * Base class for widgets
 *
 */
class Widget
{
    /** Parent widget */
    public var parent (get,never) : Null<Widget>;
    private var __parent (default,set) : Widget;
    /** Get amount of children */
    public var numChildren (default,null) : Int = 0;

    /** Position along X-axis measured from parent widget's left border */
    public var left (get,never) : Coordinate;
    private var __left : Coordinate;
    /** Position along X-axis measured from parent widget's right border */
    public var right (get,never) : Coordinate;
    private var __right : Coordinate;
    /** Position along Y-axis measured from parent widget's top border */
    public var top (get,never) : Coordinate;
    private var __top : Coordinate;
    /** Position along Y-axis measured from parent widget's bottom border */
    public var bottom (get,never) : Coordinate;
    private var __bottom : Coordinate;

    /** Origin point. By default it's top left corner. */
    public var origin (get,never) : Origin;
    private var __origin : Origin;

    /** Widget's width */
    public var width (get,never) : Size;
    private var __width : Size;
    /** Widget's height */
    public var height (get,never) : Size;
    private var __height : Size;

    /** Scale along X axis */
    public var scaleX (default,set) : Float = 1;
    /** Scale along Y axis */
    public var scaleY (default,set) : Float = 1;

    /** Clockwise rotation (degrees) */
    public var rotation (default,set) : Float = 0;

    /**
     * Transparency.
     * `0` - fully transparent.
     * `1` - fully opaque.
     */
    public var alpha (default,set) : Float = 1;
    /** Whether or not the display object is visible. */
    public var visible (default,set) : Bool = true;

    /** Applied skin. */
    public var skin (default,set) : Null<Skin>;

    /** "Native" backend */
    public var backend (default,null) : Backend;

    /** Signal dispatched when widget width or height is changed */
    public var onResize (default,null) : ResizeSignal;
    // /** Signal dispatched when widget position is changed */
    // public var onMove (default,null) : MoveSignal;

    /** Indicates if this widget attached listener to `parent.onResize` */
    private var __listeningParentResize : Bool = false;


    /**
     * Cosntructor
     */
    public function new () : Void
    {
        __createBackend();

        __width = new Size(Horizontal);
        __width.pctSource = __parentWidthProvider;
        __width.onChange  = __propertyResized;

        __height = new Size(Vertical);
        __height.pctSource = __parentHeightProvider;
        __height.onChange  = __propertyResized;

        __left = new Coordinate(Horizontal);
        __left.pctSource = __parentWidthProvider;
        __left.onChange  = __propertyMoved;

        __right = new Coordinate(Horizontal);
        __right.pctSource = __parentWidthProvider;
        __right.onChange  = __propertyMoved;

        __top = new Coordinate(Vertical);
        __top.pctSource = __parentHeightProvider;
        __top.onChange  = __propertyMoved;

        __bottom = new Coordinate(Vertical);
        __bottom.pctSource = __parentHeightProvider;
        __bottom.onChange  = __propertyMoved;

        __left.pair      = get_right;
        __right.pair     = get_left;
        __top.pair       = get_bottom;
        __bottom.pair    = get_top;
        __left.ownerSize = __right.ownerSize = get_width;
        __top.ownerSize  = __bottom.ownerSize = get_height;

        __left.select();
        __top.select();

        onResize = new ResizeSignal();
        // onMove   = new MoveSignal();
    }


    /**
     * Add `child` to display list of this widget.
     *
     * Returns added child.
     */
    public function addChild (child:Widget) : Widget
    {
        if (child.parent != null) child.parent.removeChild(child);

        backend.addWidget(child);
        numChildren++;
        child.__parent = this;

        return child;
    }


    /**
     * Insert `child` at specified `index` of display list of this widget..
     *
     * If `index` is negative, calculate required index from the end of display list (`numChildren` + index).
     * If `index` is out of bounds, `child` will be added to the end (positive `index`) or to the beginning
     * (negative `index`) of display list.
     *
     * Returns added `child`.
     */
    public function addChildAt (child:Widget, index:Int) : Widget
    {
        if (child.parent != null) child.parent.removeChild(child);

        backend.addWidgetAt(child, index);
        numChildren++;
        child.__parent = this;

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
        if (child.parent == this) {
            backend.removeWidget(child);
            numChildren--;
            child.__parent = null;

            return child;
        } else {
            return null;
        }
    }


    /**
     * Remove child at `index` of display list of this widget.
     *
     * If `index` is negative, calculate required index from the end of display list (`numChildren` + index).
     *
     * Returns removed child or `null` if `index` is out of bounds.
     */
    public function removeChildAt (index:Int) : Null<Widget>
    {
        var removed = backend.removeWidgetAt(index);
        if (removed != null) {
            numChildren--;
            removed.__parent = null;
        }

        return removed;
    }


    /**
     * Remove all children from child with `beginIndex` position to child with `endIndex` (including).
     *
     * If index is negative, find required child from the end of display list.
     *
     * Returns amount of children removed.
     */
    public function removeChildren (beginIndex:Int = 0, endIndex:Int = -1) : Int
    {
        if (beginIndex < 0) beginIndex = numChildren + beginIndex;
        if (beginIndex < 0) beginIndex = 0;
        if (endIndex < 0) {
            endIndex = numChildren + endIndex;
        } else if (endIndex >= numChildren) {
            endIndex = numChildren - 1;
        }

        if (beginIndex >= numChildren || endIndex < beginIndex) return 0;

        var removed = endIndex - beginIndex + 1;
        while (beginIndex <= endIndex) {
            removeChildAt(beginIndex);
            endIndex--;
        }

        return removed;
    }


    /**
     * Determines if `child` is this widget itself or if `child` is in display list of this widget at any depth.
     */
    public function contains (child:Widget) : Bool
    {
        while (child != null) {
            if (child == this) return true;
            child = child.parent;
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
        if (child.parent != this) throw new NotChildException();

        return backend.getWidgetIndex(child);
    }


    /**
     * Move `child` to specified `index` in display list.
     *
     * If `index` is greater then amount of children, `child` will be added to the end of display list.
     * If `index` is negative, required position will be calculated from the end of display list.
     * If `index` is negative and calculated position is less than zero, `child` will be added at the beginning of display list.
     *
     * Returns new position of a `child` in display list.
     *
     * @throws sx.exceptions.NotChildException If `child` is not direct child of this widget.
     */
    public function setChildIndex (child:Widget, index:Int) : Int
    {
        if (child.parent != this) throw new NotChildException();

        return backend.setWidgetIndex(child, index);
    }


    /**
     * Get child at specified `index`.
     *
     * If `index` is negative, required child is calculated from the end of display list.
     *
     * Returns child located at `index`, or returns `null` if `index` is out of bounds.
     */
    public function getChildAt (index:Int) : Null<Widget>
    {
        return backend.getWidgetAt(index);
    }


    /**
     * Swap two specified child widgets in display list.
     *
     * @throws sx.exceptions.NotChildException() If eighter `child1` or `child2` are not a child of this widget.
     */
    public function swapChildren (child1:Widget, child2:Widget) : Void
    {
        if (child1.parent != this || child2.parent != this) throw new NotChildException();
        backend.swapWidgets(child1, child2);
    }


    /**
     * Swap children at specified indexes.
     *
     * If indices are negative, required children are calculated from the end of display list.
     *
     * @throws sx.exceptions.OutOfBoundsException
     */
    public function swapChildrenAt (index1:Int, index2:Int) : Void
    {
        if (index1 < 0) index1 += numChildren;
        if (index2 < 0) index2 += numChildren;

        if (index1 < 0 || index1 >= numChildren || index2 < 0 || index2 > numChildren) {
            throw new OutOfBoundsException('Provided index does not exist in display list of this widget.');
        }

        backend.swapWidgetsAt(index1, index2);
    }


    /**
     * Method to cleanup and release this object for garbage collector.
     */
    public function dispose (disposeChildren:Bool = true) : Void
    {
        if (parent != null) {
            parent.removeChild(this);
        }

        if (skin != null) skin = null;

        if (disposeChildren) {
            while (numChildren > 0) getChildAt(0).dispose(true);
        } else {
            removeChildren();
        }

        backend.widgetDisposed();

        onResize = null;
        // onMove   = null;
    }


    /**
     * Set backend instance
     */
    private function __createBackend () : Void
    {
        backend = Sx.backendFactory.forWidget(this);
    }


    /**
     * Called when `width` or `height` is changed.
     */
    private function __propertyResized (changed:Size, previousUnits:Unit, previousValue:Float) : Void
    {
        __affectParentResizeListener(changed, previousUnits, previousValue);
        __resized(changed, previousUnits, previousValue);
    }


    /**
     * Called when widget resized
     */
    private inline function __resized (changed:Size, previousUnits:Unit, previousValue:Float) : Void
    {
        backend.widgetResized();
        onResize.dispatch(this, changed, previousUnits, previousValue);
    }


    /**
     * Called when `left`, `right`, `bottom` or `top` are changed.
     */
    private function __propertyMoved (changed:Size, previousUnits:Unit, previousValue:Float) : Void
    {
        __affectParentResizeListener(changed, previousUnits, previousValue);
        __moved(changed, previousUnits, previousValue);
    }


    /**
     * Called when widget position changed
     */
    private inline function __moved (changed:Size, previousUnits:Unit, previousValue:Float) : Void
    {
        backend.widgetMoved();
        // onMove.dispatch(this, changed, previousUnits, previousValue);
    }


    /**
     * Called when some property of `skin` was changed or skin removed/attached
     */
    private function __skinChanged () : Void
    {
        backend.widgetSkinChanged();
    }


    /**
     * Called when `origin` is changed.
     */
    private function __originChanged () : Void
    {
        backend.widgetOriginChanged();
    }


    /**
     * Provides values for percentage calculations of width, left and right properties
     */
    private function __parentWidthProvider () : Size
    {
        return (parent == null ? Size.zeroProperty : parent.width);
    }


    /**
     * Provides values for percentage calculations of height, top and bottom properties
     */
    private function __parentHeightProvider () : Size
    {
        return (parent == null ? Size.zeroProperty : parent.height);
    }


    /**
     * Listener for parent size changes
     */
    private function __parentResized (parent:Widget, changed:Size, previousUnits:Unit, previousValue:Float) : Void
    {
        //parent width changed
        if (changed.isHorizontal()) {

            //check width
            if (width.units == Percent) {
                __resized(width, Percent, width.pct);
            }

            //check position along X axis
            if (left.selected) {
                if (left.units == Percent) __moved(left, Percent, left.pct);
            } else {
                __moved(right, Percent, right.pct);
            }

        //parent height changed
        } else {

            //check height
            if (height.units == Percent) {
                __resized(height, Percent, height.pct);
            }

            //check position along Y axis
            if (top.selected) {
                if (top.units == Percent) __moved(top, Percent, top.pct);
            } else {
                __moved(bottom, Percent, bottom.pct);
            }
        }
    }


    /**
     * Add/remove parent onResize listener when this widget moved/resized.
     */
    private inline function __affectParentResizeListener (changed:Size, previousUnits:Unit, previousValue:Float) : Void
    {
        if (parent != null) {
            if (__listeningParentResize) {
                //right & bottom always depend on parent size
                if (changed != __right && changed != __top) {
                    //moved away from percentage
                    if (previousUnits == Percent && previousUnits != changed.units) {
                        __updateParentResizeListener();
                    }
                }
            } else {
                if (changed.units == Percent || changed == __right || changed == __bottom) {
                    __listeningParentResize = true;
                    parent.onResize.invoke(__parentResized);
                }
            }
        }
    }


    /**
     * Add/remove listener to parent.onResize.
     */
    private function __updateParentResizeListener () : Void
    {
        var size     = this.sizeDependsOnParent();
        var position = this.positionDependsOnParent();

        if (size || position) {
            __listeningParentResize = true;
            parent.onResize.invoke(__parentResized);
        } else if (!size && !position) {
            __listeningParentResize = false;
            parent.onResize.dontInvoke(__parentResized);
        }
    }


    /**
     * Setter for `rotation`
     */
    private function set_rotation (rotation:Float) : Float
    {
        this.rotation = rotation;
        backend.widgetRotated();

        return rotation;
    }


    /**
     * Setter for `scaleX`
     */
    private function set_scaleX (scaleX:Float) : Float
    {
        this.scaleX = scaleX;
        backend.widgetScaledX();

        return scaleX;
    }


    /**
     * Setter for `scaleY`
     */
    private function set_scaleY (scaleY:Float) : Float
    {
        this.scaleY = scaleY;
        backend.widgetScaledY();

        return scaleY;
    }


    /**
     * Setter for `alpha`
     */
    private function set_alpha (alpha:Float) : Float
    {
        this.alpha = alpha;
        backend.widgetAlphaChanged();

        return alpha;
    }


    /**
     * Setter `visible`
     */
    private function set_visible (visible:Bool) : Bool
    {
        this.visible = visible;
        backend.widgetVisibilityChanged();

        return visible;
    }


    /**
     * Setter `skin`
     */
    private function set_skin (value:Skin) : Skin
    {
        if (skin != null) {
            skin.onChange = null;
            skin.removed();
        }

        skin = value;

        if (skin != null) {
            skin.onChange = __skinChanged;
            skin.usedBy(this);
        }
        __skinChanged();

        return value;
    }


    /**
     * Getter for `origin`
     */
    private function get_origin () : Origin
    {
        if (__origin == null) {
            __origin = new Origin(get_width, get_height);
            __origin.onChange = __originChanged;
        }

        return __origin;
    }


    /**
     * Setter `__parent`
     */
    private inline function set___parent (value:Widget) : Widget
    {
        if (__listeningParentResize && parent != null) {
            __listeningParentResize = false;
            parent.onResize.dontInvoke(__parentResized);
        }

        __parent = value;
        if (__parent != null) __updateParentResizeListener();

        return value;
    }


    /** Getters */
    private function get_parent ()          return __parent;
    private function get_width ()           return __width;
    private function get_height ()          return __height;
    private function get_left ()            return __left;
    private function get_right ()           return __right;
    private function get_top ()             return __top;
    private function get_bottom ()          return __bottom;


}//class Widget