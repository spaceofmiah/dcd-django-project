from django.db import models


class Todo(models.Model):
    """Models an activity to be done"""
    activity = models.CharField(max_length=225, blank=False, null=False)
    priority = models.CharField(max_length=50, default="important")
    date_created = models.DateTimeField(auto_now_add=True)
    attachment = models.FileField()

    def __str__(self) -> str:
        """Returns a human friendly string representation of model instance"""
        return f"{self.activity} [{self.priority}]"
