using Toybox.WatchUi;

class DiceDelegate extends WatchUi.BehaviorDelegate {
    hidden var view;
    hidden var last_forward;

    function initialize() {
        self.view = null;
        BehaviorDelegate.initialize();
    }

    function onNextPage() {
        return self.onNextMode();
    }

    function onSelect() {
        return self.onMenu();
//        return self.onNextMode();
    }

    function onNextMode() {
        WatchUi.requestUpdate();

        return true;
    }

    function onPreviousMode() {
        WatchUi.requestUpdate();

        return true;
    }

    function onPreviousPage() {
        return self.onPreviousMode();
    }

    function onMenu() {
        /* var menu = new WatchUi.Menu2({:title=>"My Menu2"}); */
        /* var delegate; */
        /* menu.addItem( */
        /*     new MenuItem( */
        /*         "Item 1 Label", */
        /*         null, */
        /*         /\* "Item 1 subLabel", *\/ */
        /*         "itemOneId", */
        /*         {} */
        /*     ) */
        /* ); */
        /* menu.addItem( */
        /*     new MenuItem( */
        /*         "Item 2 Label", */
        /*         "Item 2 subLabel", */
        /*         "itemTwoId", */
        /*         {} */
        /*     ) */
        /* ); */
        /* delegate = new MyMenu2InputDelegate(); // a WatchUi.Menu2InputDelegate */
        /* WatchUi.pushView(menu, delegate, WatchUi.SLIDE_IMMEDIATE); */
        return true;
    }
}
