package sx.backend.interfaces;

import sx.backend.Backend;
import sx.widgets.Widget;


/**
 * Backend factory interface.
 *
 * Constructor should take no arguments.
 */
interface IBackendFactory
{

    /**
     * Create backend for simple widget
     */
    public function forWidget (widget:Widget) : Backend ;

}//interface IBackendFactory