using Toybox.Graphics;
using Toybox.WatchUi;

class LoadingView extends WatchUi.View {
    var is_visible;
    var callback;
    var target;
    var font;

    function initialize(target, callback) {
        self.is_visible = false;
        self.callback = callback;
        if("tasks".equals(target)) {
            self.target = "t";
        }
        else if("token".equals(target)) {
            self.target = "v";
        }
        else {
            self.target = "l";
        }

        View.initialize();
    }

    function onShow() {
        self.is_visible = true;
        if(self.callback != null) {
            self.callback.invoke();
        }
    }

    function onHide() {
        self.is_visible = false;
    }

    function onLayout(dc) {
        if(dc.getWidth() > 300) {
            self.font = WatchUi.loadResource(Rez.Fonts.icon_font_128);
        }
        else {
            self.font = WatchUi.loadResource(Rez.Fonts.icon_font_72);
        }
    }

    function onUpdate(dc) {
        View.onUpdate(dc);

        var centering = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var x = dc.getWidth()/4;
        var y = dc.getHeight()/2;

        dc.setColor(0x55AA55, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, self.font, "W", centering);
        dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(2*x, y, self.font, self.target, centering);
        dc.drawText(3*x, y, self.font, "w", centering);
        dc.drawText(3*x, y, self.font, "s", centering);
    }
}
