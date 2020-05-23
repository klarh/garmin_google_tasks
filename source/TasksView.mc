using Toybox.System;
using Toybox.WatchUi;

class TasksDelegate extends WatchUi.Menu2InputDelegate {
    var task_authenticator;

    function initialize(task_authenticator) {
        Menu2InputDelegate.initialize();
        self.task_authenticator = task_authenticator;
    }

    function onSelect(item) {
        self.task_authenticator.get().toggleTask(item.getId());
//        self.task_authenticator.get().listTasks(item.getId());
    }
}

class TasksView extends WatchUi.CheckboxMenu {
    function initialize(task_titles, task_notes, task_ids, task_checks, list_name) {
        CheckboxMenu.initialize({:title => list_name});

        for(var i = 0; i < task_titles.size(); i++) {
            self.addItem(
                new WatchUi.CheckboxMenuItem(
                    task_titles[i],
                    task_notes[i],
                    task_ids[i],
                    task_checks[i],
                    {}
                    ));
        }
    }
}
