using Toybox.WatchUi;

class PhoneView extends WatchUi.View {
    var font;

    function initialize() {
        View.initialize();
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

        dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, self.font, "n", centering);
        dc.drawText(2*x, y, self.font, "v", centering);
        dc.setColor(0xAAAAAA, Graphics.COLOR_TRANSPARENT);
        dc.drawText(3*x, y, self.font, "g", centering);
    }
}
