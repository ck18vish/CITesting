/****** Object:  Table [dbo].[job_status]    Script Date: 06-Dec-2018 03:03:25 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[job_status](
	[jobStatusId] [bigint] IDENTITY(1,1) NOT NULL,
	[filesProcessed] [bigint] NOT NULL,
	[startTime] [datetime] NULL,
	[endTime] [datetime] NULL,
 CONSTRAINT [PK_jobStatus] PRIMARY KEY CLUSTERED 
(
	[jobStatusId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


