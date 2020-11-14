$(function() {
    $("a[data-category]").on("click", function() {

        var category = $(this).data("category");
        var action = $(this).data("action");
        var label = $(this).data("label");

        var target = $(this).attr("target");
        var url = $(this).attr("href");

        /* For downloads use the downloaded file as label. Keep the filenames pretty. */
        if ("Downloads" === category) {
            label = url;
        }

        try {
            _gaq.push(["_trackEvent", category, action, label]);
        } catch(error) {
            console.log(error);
        }

        if (target) {
            window.open(url, target);
        } else {
            /* Give Google Analytics some time to record the event. */
            setTimeout(function() {
                window.location = url;
            }, 100);
        }
        return false;
    });
});
