package com.shaunhusain.fingerPainting.view
{
	import com.eclecticdesignstudio.motion.Actuate;
	import com.shaunhusain.fingerPainting.managers.AccelerometerManager;
	import com.shaunhusain.fingerPainting.model.PaintModel;
	import com.shaunhusain.fingerPainting.tools.BlankTool;
	import com.shaunhusain.fingerPainting.tools.BrushTool;
	import com.shaunhusain.fingerPainting.tools.BucketTool;
	import com.shaunhusain.fingerPainting.tools.CameraTool;
	import com.shaunhusain.fingerPainting.tools.ColorSpectrumTool;
	import com.shaunhusain.fingerPainting.tools.EraserTool;
	import com.shaunhusain.fingerPainting.tools.GalleryTool;
	import com.shaunhusain.fingerPainting.tools.ITool;
	import com.shaunhusain.fingerPainting.tools.LayerTool;
	import com.shaunhusain.fingerPainting.tools.NavigationTool;
	import com.shaunhusain.fingerPainting.tools.PipetTool;
	import com.shaunhusain.fingerPainting.tools.RedoTool;
	import com.shaunhusain.fingerPainting.tools.SaveTool;
	import com.shaunhusain.fingerPainting.tools.UndoTool;
	import com.shaunhusain.fingerPainting.view.managers.HelpManager;
	import com.shaunhusain.fingerPainting.view.managers.SecondaryPanelManager;
	import com.shaunhusain.fingerPainting.view.mobileUIControls.ButtonScroller;
	import com.shaunhusain.fingerPainting.view.mobileUIControls.RotatingIconButton;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TouchEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.utils.setTimeout;
	
	import org.bytearray.ScaleBitmap;
	
	/**
	 * Contains the setup for the scrolling menu buttons for the main toolbar
	 * and handler code.  Also contains the code for opening/closing the
	 * toolbar and animating the open/close arrow.
	 */
	public class Toolbar extends Sprite
	{
		private var br:BitmapReference = BitmapReference.getInstance();
		
		private var model:PaintModel = PaintModel.getInstance();
		
		private var secondaryPanelManager:SecondaryPanelManager = SecondaryPanelManager.getIntance();
		
		private var isOpen:Boolean;
		
		private var _arrowRotation:Number=0;
		
		private var triangleSprite:Sprite;
		
		//Used to hold all the buttons in case they
		//need to be scrolled
		private var menuButtonSprite:ButtonScroller;
		
		private var mainToolbarStartPoint:Point;
		private var toolbarMoved:Boolean;
		
		//--------------------------------------------------------------------------------
		//				Constructor
		//--------------------------------------------------------------------------------
		public function Toolbar()
		{
			super();
			//waiting for added to stage to add the rest of children so
			//the full screen size can be accounted for
			addEventListener(Event.ADDED_TO_STAGE, handleAddedToStage);
			
			addEventListener(TouchEvent.TOUCH_BEGIN, handleTouchBegin);
			addEventListener(TouchEvent.TOUCH_END, handleTouchEnd);
			addEventListener(TouchEvent.TOUCH_TAP, handleTapped);
			addEventListener(TouchEvent.TOUCH_MOVE, touchMoveHandler);
			addEventListener(TouchEvent.TOUCH_ROLL_OUT, handleRollout);
			
			model.currentColorBitmap = br.getBitmapByName("colorSpectrumIcon.png");
		}
		
		//--------------------------------------------------------------------------------
		//				Properties
		//--------------------------------------------------------------------------------
		public function set arrowRotation(angleRadians:Number):void
		{
			rotateTriangle(angleRadians);	
		}
		public function get arrowRotation():Number
		{
			return _arrowRotation;
		}
		
		//--------------------------------------------------------------------------------
		//				Handlers
		//--------------------------------------------------------------------------------
		private function handleAddedToStage(event:Event):void
		{
			var dpi:Number = Capabilities.screenDPI;
			var dpiScale:Number = model.dpiScale;
			//Setting up the background scale9Grid and scaling
			var scaledBitmap:ScaleBitmap = new ScaleBitmap(BitmapReference.getInstance().getBitmapByName("toolbarBackground.png").bitmapData);
			scaledBitmap.scale9Grid = new Rectangle(107 * dpiScale, 102*dpiScale, 188*dpiScale, 2325*dpiScale);
			scaledBitmap.height = stage.fullScreenHeight - y - 20;
			//toolbarBmp.width = toolbarBmp.scaleY*toolbarBmp.width;
			addChild(scaledBitmap);
			
			//Setting up the triangle button that spins when opening
			rotateTriangle(Math.PI);
			triangleSprite = new Sprite();
			triangleSprite.x = 41*dpiScale;
			triangleSprite.y = 35*dpiScale;
			addChild(triangleSprite);
			
			triangleSprite.addChild(br.getBitmapByName("triangleIcon.png"));
			
			//Setting up the hit area so the entire toolbar doesn't respond to events
			var hitAreaSprite:Sprite = new Sprite();
			hitAreaSprite.graphics.clear();
			hitAreaSprite.graphics.beginFill(0x000000);
			hitAreaSprite.graphics.drawRect(0,0,1000,100);
			hitAreaSprite.graphics.endFill();
			hitAreaSprite.visible = false;
			addChild(hitAreaSprite);
			hitArea = hitAreaSprite;
			
			menuButtonSprite = new ButtonScroller();
			menuButtonSprite.buttonMaskHeight = stage.fullScreenHeight-180*dpiScale;
			menuButtonSprite.buttonMaskWidth = 175 * dpiScale;
			menuButtonSprite.y = 100*dpiScale;
			menuButtonSprite.x = 120*dpiScale;
			addChild(menuButtonSprite);
			menuButtonSprite.addEventListener("instantaneousButtonClicked", instantaneousActionHandler);
			menuButtonSprite.addEventListener("buttonClicked", deselectAllOthers);
			
			var bg:Bitmap = br.getBitmapByName("buttonBackgroundTrans.png");
			var bgs:Bitmap = br.getBitmapByName("buttonBackgroundSelectedYellow.png");
			
			var brushTool:BrushTool = new BrushTool(stage);
			model.currentTool = brushTool;
			menuButtonSprite.menuButtons = 
				[
					new RotatingIconButton(br.getBitmapByName("colorSpectrumIcon.png"), null, new ColorSpectrumTool(stage), true, false, true,bg,bgs),
					new RotatingIconButton(br.getBitmapByName("brushIcon.png"), null, brushTool, false, true, true, bg, bgs),
					new RotatingIconButton(br.getBitmapByName("eraserIcon.png"), null, new EraserTool(stage), false, false, true, bg, bgs),
					new RotatingIconButton(br.getBitmapByName("bucketIcon.png"), null, new BucketTool(stage), false, false, true, bg, bgs),
					new RotatingIconButton(br.getBitmapByName("navigationIcon.png"), null, new NavigationTool(stage), false, false, true, bg, bgs),
					new RotatingIconButton(br.getBitmapByName("pipetIcon.png"), null, new PipetTool(stage), false, false, true, bg, bgs),
					new RotatingIconButton(br.getBitmapByName("undoIcon.png"), null, new UndoTool(stage), true, false, true, bg, bgs),
					new RotatingIconButton(br.getBitmapByName("redoIcon.png"), null, new RedoTool(stage), true, false, true, bg, bgs),
					new RotatingIconButton(br.getBitmapByName("blankDocIcon.png"), null, new BlankTool(stage), true, false, true, bg, bgs),
					new RotatingIconButton(br.getBitmapByName("layersIcon.png"), null, new LayerTool(stage), false, false, true, bg, bgs),
					new RotatingIconButton(br.getBitmapByName("cameraIcon.png"), null, new CameraTool(stage), true, false, true, bg, bgs),
					new RotatingIconButton(br.getBitmapByName("galleryIcon.png"), null, new GalleryTool(stage), true, false, true, bg, bgs),
					/*new RotatingIconButton(br.getBitmapByName("shareIcon.png"), null, new ShareTool(stage), true, false, true, bg, bgs),*/
					new RotatingIconButton(br.getBitmapByName("saveIcon.png"), null, new SaveTool(stage), true, false, true, bg, bgs)
				];
		}
		
		//--------------------------------------------------------------------------------
		//				Handlers
		//--------------------------------------------------------------------------------
		private function handleTouchBegin(event:TouchEvent):void
		{
			event.stopImmediatePropagation();
			toolbarMoved = false;
			mainToolbarStartPoint = new Point(event.stageX,event.stageY);
		}
		
		private function touchMoveHandler(event:TouchEvent):void
		{
			event.stopImmediatePropagation();
			if(!mainToolbarStartPoint)
				return;
			
			var xChange:Number = mainToolbarStartPoint.x - event.stageX;
			if(toolbarMoved||Math.abs(xChange) > 5)
			{
				model.toolbarMoving = toolbarMoved = true;
				mainToolbarStartPoint.x = event.stageX;
				x -= xChange;
				if(x<stage.fullScreenWidth - 270)
					x = stage.fullScreenWidth - 270;
			}
		}
		
		private function handleTouchEnd(event:TouchEvent):void
		{
			event.stopImmediatePropagation();
			if(toolbarMoved)
			{
				setTimeout(function():void{model.toolbarMoving = false},500);
			}
			mainToolbarStartPoint = null;
		}
		
		private function handleTapped(event:TouchEvent):void
		{
			event.stopImmediatePropagation();
			
			if(isOpen)
			{
				AccelerometerManager.getIntance().currentlyActive = false;
				Actuate.tween(this, .5, {arrowRotation:Math.PI, x:stage.fullScreenWidth - FingerPainting.TOOLBAR_OFFSET_FROM_RIGHT*model.dpiScale});
			}
			else
			{
				AccelerometerManager.getIntance().currentlyActive = true;
				Actuate.tween(this, .5, {arrowRotation:0,x:stage.fullScreenWidth - FingerPainting.TOOLBAR_OFFSET_FROM_RIGHT_OPEN*model.dpiScale});
			}
			isOpen = !isOpen;
			secondaryPanelManager.hidePanel();
		}
		
		protected function handleRollout(event:TouchEvent):void
		{
			if(!mainToolbarStartPoint)
				return;
			var xChange:Number = mainToolbarStartPoint.x - event.stageX;
			if(xChange<0)
			{
				isOpen = true;
				AccelerometerManager.getIntance().currentlyActive = true;
				Actuate.tween(this, .5, {arrowRotation:0,x:stage.fullScreenWidth - 270});
			}
			else
			{
				isOpen = false;
				AccelerometerManager.getIntance().currentlyActive = false;
				Actuate.tween(this, .5, {arrowRotation:Math.PI, x:stage.fullScreenWidth - 85});
				secondaryPanelManager.hidePanel();
			}
		}
		
		private function blockEvent(event:TouchEvent):void
		{
			event.stopImmediatePropagation();
		}
		
		protected function instantaneousActionHandler(event:Event):void
		{
			var tempTool:ITool = event.target.data as ITool;
			HelpManager.getIntance().showMessage((event.target.data as ITool).toString(),500,false);
			tempTool.takeAction();
		}
		
		//--------------------------------------------------------------------------------
		//				Helper functions
		//--------------------------------------------------------------------------------
		private function deselectAllOthers(event:Event):void
		{
			if(model.currentTool != event.target.data as ITool)
				HelpManager.getIntance().showMessage((event.target.data as ITool).toString(),2000,false);
			
			if(model.currentTool == event.target.data as ITool && model.currentTool is BrushTool)
			{
				var bt:BrushTool = model.currentTool as BrushTool;
				bt.toggleSecondaryOptions();
			}
			else if(model.currentTool == event.target.data as ITool && model.currentTool is LayerTool)
			{
				var yt:LayerTool = model.currentTool as LayerTool;
				yt.toggleSecondaryOptions();
			}
			else if(model.currentTool == event.target.data as ITool && model.currentTool is NavigationTool)
			{
				var nt:NavigationTool = model.currentTool as NavigationTool;
				nt.resetZoomAndPosition();
			}
			else
			{
				secondaryPanelManager.hidePanel();
			}
			
			model.currentTool = event.target.data as ITool;
			
			
			for( var i:int = 0; i <menuButtonSprite.menuButtons.length; i++)
			{
				var ab:RotatingIconButton = menuButtonSprite.menuButtons[i];
				if(event.target!=ab)
					ab.isSelected = false;
			}
		}
		
		private function rotateTriangle(angleRadians:Number):void
		{
			var triangleIcon:Bitmap = br.getBitmapByName("triangleIcon.png");
			
			_arrowRotation = angleRadians;
			
			var m:Matrix = triangleIcon.transform.matrix;
			m.identity();
			m.translate(-triangleIcon.width/2,-triangleIcon.height/2);
			m.rotate(angleRadians);
			m.translate(triangleIcon.width/2,triangleIcon.height/2);
			triangleIcon.transform.matrix = m;
		}
	}
}