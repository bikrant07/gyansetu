document.addEventListener("DOMContentLoaded", () => {
    console.log("Virtual Lab initialized");

    // Tab switching functionality
    const tabBtns = document.querySelectorAll('.tab-btn');
    const subjectContents = document.querySelectorAll('.subject-content');

    tabBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            // Remove active class from all tabs and contents
            tabBtns.forEach(b => b.classList.remove('active'));
            subjectContents.forEach(content => content.classList.remove('active'));

            // Add active class to clicked tab and corresponding content
            btn.classList.add('active');
            const subject = btn.dataset.subject;
            document.getElementById(subject).classList.add('active');

            // Show progress for selected subject
            document.querySelectorAll('.overall-progress-container').forEach(container => {
                if (container.classList.contains(`${subject}-progress`)) {
                    container.style.display = 'block';
                } else {
                    container.style.display = 'none';
                }
            });
        });
    });

    // Show initial progress for active tab
    const activeSubject = document.querySelector('.tab-btn.active').dataset.subject;
    document.querySelectorAll('.overall-progress-container').forEach(container => {
        if (container.classList.contains(`${activeSubject}-progress`)) {
            container.style.display = 'block';
        } else {
            container.style.display = 'none';
        }
    });
});
