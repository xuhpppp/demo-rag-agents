import asyncio
import logging
from dataclasses import dataclass, field
from datetime import datetime

logger = logging.getLogger(__name__)


@dataclass
class FileJob:
    filename: str
    filepath: str
    size_bytes: int
    uploaded_at: str = field(default_factory=lambda: datetime.now().isoformat())


class FileQueue:
    def __init__(self):
        self._queue: asyncio.Queue[FileJob] = asyncio.Queue()

    async def push(self, job: FileJob):
        await self._queue.put(job)
        logger.info(f"Job queued: {job.filename} ({job.size_bytes} bytes)")

    async def pop(self) -> FileJob:
        return await self._queue.get()

    def done(self):
        self._queue.task_done()

    def size(self) -> int:
        return self._queue.qsize()

    def empty(self) -> bool:
        return self._queue.empty()


file_queue = FileQueue()
