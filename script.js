function selectTab(tab, contentId) {
    // Remove active class from all tabs
    const tabs = document.querySelectorAll('.tab');
    tabs.forEach(t => t.classList.remove('active'));

    // Add active class to the selected tab
    tab.classList.add('active');

    // Hide all content
    const contents = document.querySelectorAll('.content');
    contents.forEach(c => c.classList.remove('active'));

    // Show the selected content
    document.getElementById(contentId).classList.add('active');
}

// Optionally, select the first tab by default
window.onload = function() {
    selectTab(document.getElementById('tab1'), 'content1');
};