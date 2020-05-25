using Toybox.WatchUi;

class ErrorView extends WatchUi.View {
    var code;
    var data;
    var font;

    function initialize(code, data) {
        self.code = code;
        self.data = data;

        View.initialize();
    }

    function onLayout(dc) {
        setLayout(Rez.Layouts.ErrorScreen(dc));

        var code_label = View.findDrawableById("error_code");
        code_label.setText(self.code.toString());
        var data_label = View.findDrawableById("error_text");
        data_label.setText(self.data.toString());

        self.font = WatchUi.loadResource(Rez.Fonts.icon_font_72);
    }

    function onUpdate(dc) {
        View.onUpdate(dc);

        var centering = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var x = dc.getWidth()/4;
        var y = dc.getHeight()/2;

        dc.setColor(0xAA5555, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, self.font, "W", centering);
        dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(2*x, y, self.font, "x", centering);
        dc.drawText(3*x, y, self.font, "w", centering);
        dc.drawText(3*x, y, self.font, "f", centering);
    }
}
