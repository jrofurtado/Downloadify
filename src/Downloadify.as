/**
 * Downloadify: Client Side File Creation
 * JavaScript + Flash Library
 *
 * @author Douglas C. Neiner <http://code.dougneiner.com/>
 * @version 0.2
 *
 * Copyright (c) 2009 Douglas C. Neiner
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
package {
    import flash.display.*;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.external.ExternalInterface;
    import flash.net.FileFilter;
    import flash.net.FileReference;
    import flash.net.URLRequest;
    import flash.system.Security;
    import flash.utils.ByteArray;

    import com.dynamicflash.util.Base64;

    [SWF(backgroundColor="#CCCCCC")]
    [SWF(backgroundAlpha=0)]
    public class Downloadify extends Sprite
    {
        // button states
        private var down:Boolean = false;
        private var enabled:Boolean = true;
        private var over:Boolean = false;

        private var button:DisplayObject;

        private var file:FileReference = new FileReference();

        private var _width:Number = 0;
        private var _height:Number = 0;

        private var buttonImage:String = "images/download.png";
        private var queue_name:String = "";

        /**
         * Create a transparent Sprite with w * h dimensions
         * @param w The width
         * @param h The height
         * @return The Sprite
         */
        public static function createTransparentSprite( w:Number, h:Number ):Sprite
        {
            var sprite:Sprite = new Sprite();
            sprite.graphics.beginFill( 0xffffff );
            sprite.graphics.drawRect( 0, 0, w, h );
            sprite.graphics.endFill();
            sprite.alpha = 0;
            return sprite;
        }

        /**
         * Load an image from a URL
         * @param location The location of the image
         * @return The loaded image
         */
        public static function loadImage( location:String ):Loader
        {
            var loader:Loader = new Loader();
            var urlReq:URLRequest = new URLRequest( location );
            loader.load( urlReq );
            return loader;
        }

        /**
         * Constructs a new Downloadify instance
         */
        public function Downloadify()
        {
            // configure the security context
            Security.allowDomain( '*' );

            // configure the stage
            stage.align = StageAlign.TOP_LEFT;
            stage.scaleMode = StageScaleMode.NO_SCALE;

            var options:Object = this.root.loaderInfo.parameters;
            this.queue_name = options.queue_name.toString();
            this._width = options.width;
            this._height = options.height;

            if ( options.hidden == 'true' ) {
                // use a transparent sprite for the save button - the height is x4 for animations
                this.button = Downloadify.createTransparentSprite( this._width, 4 * this._height );
                this.buttonImage = null;
            } else {
                // use an external image for the save button
                if ( options.downloadImage && options.downloadImage != 'null' ) {
                    this.buttonImage = options.downloadImage;
                }
                this.button = Downloadify.loadImage( this.buttonImage );
            }

            addChild( this.button );

            this.buttonMode = true;

            this.addEventListener( MouseEvent.CLICK, onMouseClickEvent );
            this.addEventListener( MouseEvent.ROLL_OVER, onMouseEnter );
            this.addEventListener( MouseEvent.ROLL_OUT, onMouseLeave );
            this.addEventListener( MouseEvent.MOUSE_DOWN, onMouseDown );
            this.addEventListener( MouseEvent.MOUSE_UP, onMouseUp );

            ExternalInterface.addCallback( 'setEnabled', setEnabled );

            this.file.addEventListener( Event.COMPLETE, onSaveComplete );
            this.file.addEventListener( Event.CANCEL, onSaveCancel );
        }

        /**
         * Enable or disable the save button
         * @param isEnabled True if the button should respond to mouse events
         */
        public function setEnabled( isEnabled:Boolean ):void
        {
            this.enabled = isEnabled;
            if ( this.enabled === true ) {
                this.button.y = 0;
                this.buttonMode = true;
            } else {
                this.button.y = (-3 * this._height);
                this.buttonMode = false;
            }
        }

        /**
         * Handle the save button's MouseEvent.ROLL_OVER event
         * @param event
         */
        protected function onMouseEnter( event:Event ):void
        {
            if ( this.enabled === true ) {
                if ( this.down === false ) {
                    this.button.y = (-1 * this._height);
                }
                this.over = true;
            }
        }

        /**
         * Handle the save button's MouseEvent.ROLL_OUT event
         * @param event
         */
        protected function onMouseLeave( event:Event ):void
        {
            if ( this.enabled === true ) {
                if ( this.down === false ) {
                    this.button.y = 0;
                }
                this.over = false;
            }
        }

        /**
         * Handle the save button's MouseEvent.MOUSE_DOWN event
         * @param event
         */
        protected function onMouseDown( event:Event ):void
        {
            if ( this.enabled === true ) {
                this.button.y = this.button.y = (-2 * this._height);
                this.down = true;
            }
        }

        /**
         * Handle the save button's MouseEvent.MOUSE_UP event
         * @param event
         */
        protected function onMouseUp( event:Event ):void
        {
            if ( this.enabled === true ) {
                if ( this.over === false ) {
                    this.button.y = 0;
                } else {
                    this.button.y = (-1 * this._height);
                }
                this.down = false;
            }
        }

        /**
         * Handle the save button's MouseEvent.CLICK event
         * @param event
         */
        protected function onMouseClickEvent( event:Event ):void
        {
            if ( !this.enabled ) {
                return;
            }

            var theData:String = ExternalInterface.call( 'Downloadify.getTextForSave', this.queue_name );
            var filename:String = ExternalInterface.call( 'Downloadify.getFileNameForSave', this.queue_name );
            var dataType:String = ExternalInterface.call( 'Downloadify.getDataTypeForSave', this.queue_name );

            if ( dataType == "string" && theData != "" ) {
                this.file.save( theData, filename );
            } else if ( dataType == "base64" && theData ) {
                this.file.save( Base64.decodeToByteArray( theData ), filename );
            } else {
                onSaveError();
            }
        }

        /**
         * JavaScript callback when the file save operation has completed
         * @param event
         */
        protected function onSaveComplete( event:Event ):void
        {
            trace( 'Save Complete' );
            ExternalInterface.call( 'Downloadify.saveComplete', this.queue_name );
        }

        /**
         * JavaScript callback when the file save operation has been cancelled
         * @param event
         */
        protected function onSaveCancel( event:Event ):void
        {
            trace( 'Save Cancel' );
            ExternalInterface.call( 'Downloadify.saveCancel', this.queue_name );
        }

        /**
         * JavaScript callback when the file save operation encounters an error
         */
        protected function onSaveError():void
        {
            trace( 'Save Error' );
            ExternalInterface.call( 'Downloadify.saveError', this.queue_name );
        }
    }
}