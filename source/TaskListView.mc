using Toybox.System;
using Toybox.WatchUi;

class TaskListDelegate extends WatchUi.Menu2InputDelegate {
    var task_authenticator;

    function initialize(task_authenticator) {
        Menu2InputDelegate.initialize();
        self.task_authenticator = task_authenticator;
    }

    function onSelect(item) {
        self.task_authenticator.get().listTasks(item.getId(), item.getLabel());
    }
}

class TaskListView extends WatchUi.Menu2 {
    function initialize(task_list_names, task_list_ids) {
        Menu2.initialize({:title => "Tasks"});

        for(var i = 0; i < task_list_names.size(); i++) {
            self.addItem(new WatchUi.MenuItem(task_list_names[i], "", task_list_ids[i], {}));
        }
    }
}
